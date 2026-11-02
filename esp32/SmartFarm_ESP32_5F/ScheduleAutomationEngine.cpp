#include "ScheduleAutomationEngine.h"
#include <math.h>

void ScheduleAutomationEngine::begin(Preferences &p, ClockService &c, RelayManager &r, EventLog &e, StateManager &s) {
  _prefs=&p; _clock=&c; _relays=&r; _events=&e; _state=&s; load();
}

const char *ScheduleAutomationEngine::stateName(DeviceRuntimeState s) {
  switch(s){case DeviceRuntimeState::WAITING:return "waiting";case DeviceRuntimeState::RUNNING:return "running";case DeviceRuntimeState::BLOCKED:return "blocked";case DeviceRuntimeState::OVERRIDE:return "override";case DeviceRuntimeState::ERROR:return "error";default:return "off";}
}
int ScheduleAutomationEngine::find(const String&id)const{for(size_t i=0;i<_count;i++)if(_rules[i].id==id)return (int)i;return -1;}
int ScheduleAutomationEngine::findDevice(const String&id)const{for(size_t i=0;i<_count;i++)if(_rules[i].deviceId==id)return (int)i;return -1;}

uint32_t ScheduleAutomationEngine::controlledRelayMask() const {
  uint32_t mask = 0;
  for (size_t i = 0; i < _count; ++i) {
    const ScheduleRule &rule = _rules[i];
    const bool automationOwned = rule.controlMode != "manual" ||
                                 rule.scheduleEnabled ||
                                 rule.conditionCount > 0;
    if (automationOwned && rule.relayChannel < 32) {
      mask |= (1UL << rule.relayChannel);
    }
  }
  return mask | _quarantinedRelayMask;
}

bool ScheduleAutomationEngine::scheduleAllowsNow(const ScheduleRule &r,
                                                  const ClockSnapshot &snap) const {
  if (!r.scheduleEnabled || snap.dayOfWeek < 1 || snap.dayOfWeek > 7) return false;
  const int nowMin = snap.hour * 60 + snap.minute;
  const int startMin = r.hour * 60 + r.minute;
  const int endMin = r.endHour * 60 + r.endMinute;
  const auto dayAllowed = [&](uint8_t day) {
    return (r.dayMask & (1U << (day - 1))) != 0;
  };

  if (!r.useTimeWindow) return nowMin == startMin && dayAllowed(snap.dayOfWeek);
  if (startMin < endMin) {
    return dayAllowed(snap.dayOfWeek) && nowMin >= startMin && nowMin < endMin;
  }

  // Cross-midnight windows belong to the day on which they started.
  if (nowMin >= startMin) return dayAllowed(snap.dayOfWeek);
  if (nowMin < endMin) {
    const uint8_t previousDay = snap.dayOfWeek == 1 ? 7 : snap.dayOfWeek - 1;
    return dayAllowed(previousDay);
  }
  return false;
}

bool ScheduleAutomationEngine::scheduleOccurrenceKey(
    const ScheduleRule &r, const ClockSnapshot &snap, String &key) const {
  key = "";
  if (!_clock || !scheduleAllowsNow(r, snap)) return false;
  if (!r.useTimeWindow) {
    char buffer[48];
    snprintf(buffer, sizeof(buffer), "%04u-%02u-%02uT%02u:%02u|%s",
             snap.year, snap.month, snap.day, r.hour, r.minute, r.id.c_str());
    key = buffer;
    return true;
  }

  const int nowMin = snap.hour * 60 + snap.minute;
  const int startMin = r.hour * 60 + r.minute;
  int elapsedMinutes = nowMin - startMin;
  if (elapsedMinutes < 0) elapsedMinutes += 1440;
  const uint32_t elapsedSeconds =
      static_cast<uint32_t>(elapsedMinutes) * 60UL + snap.second;
  const uint32_t nowEpoch = _clock->epochLocal();
  if (nowEpoch < elapsedSeconds) return false;
  const uint32_t occurrenceStartEpoch = nowEpoch - elapsedSeconds;
  key = String(occurrenceStartEpoch) + "|" + r.id + "|" +
        String(r.hour) + ":" + String(r.minute);
  return true;
}

bool ScheduleAutomationEngine::validate(const ScheduleRule&r,String&error)const{
  if(r.id.isEmpty()||r.deviceId.isEmpty()){error="missing_id";return false;}
  if(r.scheduleEnabled && (r.hour>23||r.minute>59||r.endHour>23||r.endMinute>59)){error="invalid_time";return false;}
  if(r.scheduleEnabled && r.dayMask==0){error="missing_days";return false;}
  if(r.relayChannel>=RELAY_COUNT){error="relay_unavailable";return false;}
  if(r.scheduleEnabled && r.useTimeWindow && r.hour==r.endHour && r.minute==r.endMinute){error="invalid_schedule_window";return false;}
  if(r.durationSeconds<1||r.durationSeconds>MAX_AUTOMATION_RUNTIME_SECONDS){error="invalid_duration";return false;}
  if(r.maxRuntimeSeconds<r.durationSeconds||r.maxRuntimeSeconds>MAX_AUTOMATION_RUNTIME_SECONDS){error="invalid_max_runtime";return false;}
  if(r.conditionCount>4){error="too_many_conditions";return false;}
  for(uint8_t i=0;i<r.conditionCount;i++)if(r.conditions[i].sensorId.isEmpty()){error="missing_sensor_id";return false;}
  return true;
}

bool ScheduleAutomationEngine::relayBusyByHigherPriority(const ScheduleRule&candidate)const{
  for(size_t i=0;i<_count;i++){const auto&o=_rules[i];if(&o==&candidate||o.offAtMs==0)continue;if(o.relayChannel==candidate.relayChannel&&o.priority>candidate.priority)return true;}return false;
}

bool ScheduleAutomationEngine::evaluateCondition(const RuleCondition&c,String&reason)const{
  float actual=NAN;
  if(c.metric=="soil_moisture") actual=_state?_state->soilMoisture():NAN;
  else if(c.metric=="temperature") actual=_state?_state->temperature():NAN;
  else if(c.metric=="humidity") actual=(_state&&_state->hasHumidity())?_state->humidity():NAN;
  else {reason="unsupported_condition:"+c.metric;return false;}
  if(isnan(actual)){reason="sensor_unavailable:"+c.metric;return false;}
  bool ok=false;
  if(c.op=="<")ok=actual<c.value;else if(c.op=="<=")ok=actual<=c.value;else if(c.op==">")ok=actual>c.value;else if(c.op==">=")ok=actual>=c.value;else if(c.op=="between")ok=actual>=c.value&&actual<=c.valueHigh;else if(c.op=="outside")ok=actual<c.value||actual>c.valueHigh;
  if(!ok)reason=c.metric+"="+String(actual,1)+" not "+c.op+" "+String(c.value,1);return ok;
}

bool ScheduleAutomationEngine::stopThresholdReached(const RuleCondition&c)const{
  if(isnan(c.valueHigh))return false;
  float actual=NAN;
  if(c.metric=="soil_moisture")actual=_state?_state->soilMoisture():NAN;
  else if(c.metric=="temperature")actual=_state?_state->temperature():NAN;
  else if(c.metric=="humidity")actual=(_state&&_state->hasHumidity())?_state->humidity():NAN;
  if(isnan(actual))return false;
  if(c.op=="<"||c.op=="<=")return actual>=c.valueHigh;
  if(c.op==">"||c.op==">=")return actual<=c.valueHigh;
  return false;
}

DecisionResult ScheduleAutomationEngine::decide(const ScheduleRule&r,bool emergency)const{
  DecisionResult d; d.state=DeviceRuntimeState::WAITING;
  auto add=[&](const String&x){if(d.reasonCount<MAX_DECISION_REASONS)d.reasons[d.reasonCount++]=x;if(d.primaryReason.isEmpty())d.primaryReason=x;};
  if(emergency){d.state=DeviceRuntimeState::BLOCKED;add("emergency_latched");return d;}
  if(!r.enabled){d.state=DeviceRuntimeState::BLOCKED;add("rule_disabled");return d;}

  const bool clockReady=_clock&&_clock->snapshot().valid;
  const uint32_t nowEpoch=clockReady?_clock->epochLocal():0;
  if(r.forceOverride&&(r.overrideUntilEpoch==0||!clockReady||nowEpoch<r.overrideUntilEpoch)){
    d.allowed=true;d.state=DeviceRuntimeState::OVERRIDE;d.primaryReason="manual_override";return d;
  }

  // Clock is required only by an enabled schedule. Manual and sensor-only
  // devices continue to operate safely when DS3231 is absent or invalid.
  if(r.scheduleEnabled){
    if(!clockReady){d.state=DeviceRuntimeState::BLOCKED;add("clock_invalid");return d;}
    const auto snap=_clock->snapshot();
    if(!scheduleAllowsNow(r,snap))add("outside_time_condition");
  }

  bool any=false, all=true;
  for(uint8_t i=0;i<r.conditionCount;i++){String why;bool ok=evaluateCondition(r.conditions[i],why);any|=ok;all&=ok;if(!ok)add(why);}
  const bool condOk=r.conditionCount==0||(r.conditionLogic=="or"?any:all);
  if(!condOk&&d.primaryReason.isEmpty())add("conditions_not_met");
  if(relayBusyByHigherPriority(r)){d.state=DeviceRuntimeState::BLOCKED;add("relay_busy_higher_priority");return d;}

  // Cooldown uses RTC when available; otherwise elapsed millis from the last
  // run is used so clock-independent devices do not become permanently blocked.
  if(r.cooldownSeconds>0&&r.offAtMs==0){
    bool cooling=false;
    if(clockReady&&r.lastExecutionEpoch&&nowEpoch>=r.lastExecutionEpoch) cooling=(nowEpoch-r.lastExecutionEpoch)<r.cooldownSeconds;
    else if(!clockReady&&r.startedAtMs) cooling=(millis()-r.startedAtMs)<r.cooldownSeconds*1000UL;
    if(cooling)add("cooldown_active");
  }
  d.allowed=d.reasonCount==0; d.state=d.allowed?DeviceRuntimeState::RUNNING:DeviceRuntimeState::WAITING;
  if(d.allowed)d.primaryReason=r.requestedOn?"manual_request_conditions_met":"automation_conditions_met";
  return d;
}

bool ScheduleAutomationEngine::execute(ScheduleRule&r,bool emergency,String&error,bool testRun){
  DecisionResult d=decide(r,emergency);if(testRun&&d.primaryReason=="outside_time_condition"){d.allowed=true;d.state=DeviceRuntimeState::RUNNING;}
  if(!d.allowed){error=d.primaryReason;r.runtimeState=d.state;r.waitingReason=d.primaryReason;r.lastResult=error;return false;}
  if(!_relays->setTransient(r.relayChannel,true)){error="relay_failed";r.runtimeState=DeviceRuntimeState::ERROR;return false;}
  uint32_t runtimeSeconds=min(r.durationSeconds,r.maxRuntimeSeconds);
  if(r.scheduleEnabled&&r.useTimeWindow&&_clock&&_clock->snapshot().valid){
    const auto snap=_clock->snapshot();
    if(scheduleAllowsNow(r,snap)){
    const int nowMin=snap.hour*60+snap.minute;
    const int endMin=r.endHour*60+r.endMinute;
    const int remainingMinutes=endMin>nowMin?endMin-nowMin:1440-nowMin+endMin;
    const int remainingSeconds=remainingMinutes*60-static_cast<int>(snap.second);
    if(remainingSeconds>0) runtimeSeconds=min(runtimeSeconds,static_cast<uint32_t>(remainingSeconds));
    else runtimeSeconds=0;
    }
  }
  if(runtimeSeconds==0){error="outside_time_condition";r.runtimeState=DeviceRuntimeState::WAITING;_relays->setTransient(r.relayChannel,false);return false;}
  r.startedAtMs=millis();r.offAtMs=r.startedAtMs+runtimeSeconds*1000UL;r.lastExecutionEpoch=(_clock&&_clock->snapshot().valid)?_clock->epochLocal():0;r.runtimeState=d.state;r.activeReason=d.primaryReason;r.waitingReason="";r.lastResult=testRun?"test_started":"started";
  _events->add(testRun?"automation_test":"automation",r.lastResult,r.deviceId,r.relayChannel);return true;
}

void ScheduleAutomationEngine::stopRule(ScheduleRule&r,const char*reason){_relays->setTransient(r.relayChannel,false);r.offAtMs=0;r.startedAtMs=0;r.requestedOn=false;r.forceOverride=false;r.runtimeState=DeviceRuntimeState::OFF;r.activeReason="";r.lastResult=reason;_events->add("automation",reason,r.deviceId,r.relayChannel);}

void ScheduleAutomationEngine::update(bool emergency){
  if(!_relays)return;
  if(_clock)_clock->update();
  const bool clockReady=_clock&&_clock->snapshot().valid;
  const auto snap=clockReady?_clock->snapshot():ClockSnapshot{};
  const uint32_t nowEpoch=clockReady?_clock->epochLocal():0;

  for(size_t i=0;i<_count;i++){
    auto&r=_rules[i];
    const bool overrideExpired=r.forceOverride&&r.overrideUntilEpoch>0&&clockReady&&nowEpoch>=r.overrideUntilEpoch;
    if(overrideExpired){
      r.forceOverride=false;
      r.overrideUntilEpoch=0;
      const DecisionResult reconciled=decide(r,emergency);
      if(r.offAtMs&&!reconciled.allowed){
        stopRule(r,"override_expired");
      }else{
        r.runtimeState=reconciled.state;
        r.activeReason=reconciled.allowed?reconciled.primaryReason:"";
        r.waitingReason=reconciled.allowed?"":reconciled.primaryReason;
        r.lastResult="override_reconciled";
      }
      _revision++;
      save();
    }

    if(r.offAtMs){
      if(emergency){stopRule(r,"stopped_emergency");continue;}
      bool thresholdStop=false;
      for(uint8_t n=0;n<r.conditionCount;n++)if(stopThresholdReached(r.conditions[n])){thresholdStop=true;break;}
      if(thresholdStop){stopRule(r,"sensor_stop_threshold_reached");_revision++;save();continue;}
      if((int32_t)(millis()-r.offAtMs)>=0||millis()-r.startedAtMs>=r.maxRuntimeSeconds*1000UL){stopRule(r,"completed");_revision++;save();}
      continue;
    }
    if(!r.enabled||emergency)continue;

    const bool scheduled=r.scheduleEnabled&&clockReady&&scheduleAllowsNow(r,snap);
    if(!scheduled&&!r.requestedOn)continue;

    String execution;
    if(scheduled){
      if(!scheduleOccurrenceKey(r,snap,execution))continue;
      if(r.lastExecutionKey==execution&&!r.requestedOn)continue;
    }
    String err;
    if(execute(r,emergency,err)){
      if(scheduled)r.lastExecutionKey=execution;
      _revision++;
      save();
    }
  }
}

bool ScheduleAutomationEngine::requestDevice(const String&deviceId,bool on,bool force,uint32_t seconds,bool emergency,DecisionResult&result){
  int i=findDevice(deviceId);if(i<0){result.state=DeviceRuntimeState::ERROR;result.primaryReason="device_not_found";return false;}auto&r=_rules[i];
  if(!on){if(r.offAtMs)stopRule(r,"manual_stop");r.requestedOn=false;r.forceOverride=false;r.runtimeState=DeviceRuntimeState::OFF;r.waitingReason="";_revision++;save();result.allowed=true;result.state=DeviceRuntimeState::OFF;result.primaryReason="stopped";return true;}
  r.requestedOn=true;r.forceOverride=force;r.overrideUntilEpoch=force&&seconds>0&&_clock&&_clock->snapshot().valid?_clock->epochLocal()+seconds:0;result=decide(r,emergency);r.runtimeState=result.state;r.waitingReason=result.allowed?"":result.primaryReason;
  if(result.allowed){String err;if(!execute(r,emergency,err)){result.allowed=false;result.primaryReason=err;}}
  _events->add(force?"override":"request",result.primaryReason,deviceId,r.relayChannel);_revision++;save();return true;
}

bool ScheduleAutomationEngine::evaluateDevice(const String&id,bool emergency,DecisionResult&result)const{int i=findDevice(id);if(i<0){result.primaryReason="device_not_found";result.state=DeviceRuntimeState::ERROR;return false;}result=decide(_rules[i],emergency);return true;}

bool ScheduleAutomationEngine::upsertFromJson(JsonObjectConst j,String&error){
  if(j.isNull()){error="invalid_profile";return false;}
  if(!j["id"].is<const char*>()||String(j["id"].as<const char*>()).isEmpty()){error="missing_id";return false;}
  if(!j["actions"].is<JsonArrayConst>()){error="missing_action";return false;}
  ScheduleRule c;c.id=j["id"]|"";int existing=find(c.id);if(existing>=0)c=_rules[existing];
  c.id=j["id"]|c.id;c.name=j["name"]|"Automation";c.deviceType=j["deviceType"]|c.deviceType;c.controlMode=j["controlMode"]|c.controlMode;c.enabled=j["enabled"]|true;c.priority=j["priority"]|300;
  c.lastExecutionKey=j["lastExecutionKey"]|c.lastExecutionKey;
  JsonObjectConst sch=j["trigger"]["schedule"];c.hour=sch["hour"]|6;c.minute=sch["minute"]|0;c.endHour=sch["endHour"]|c.hour;c.endMinute=sch["endMinute"]|c.minute;const String scheduleMode=sch["mode"]|"at"; c.scheduleEnabled=sch["enabled"]|true; c.useTimeWindow=scheduleMode=="window"; if(scheduleMode=="always")c.scheduleEnabled=false;
  c.dayMask=0;for(JsonVariantConst d:sch["daysOfWeek"].as<JsonArrayConst>()){int day=d.as<int>();if(day>=1&&day<=7)c.dayMask|=1<<(day-1);}
  c.conditionLogic=j["conditionLogic"]|"and";c.conditionCount=0;for(JsonObjectConst x:j["conditions"].as<JsonArrayConst>()){if(c.conditionCount>=4)break;auto&cc=c.conditions[c.conditionCount++];cc.type=x["type"]|"sensor";cc.sensorId=x["sensorId"]|"";cc.metric=x["metric"]|"";cc.op=x["operator"]|"<";cc.value=x["value"]|NAN;cc.valueHigh=x["valueHigh"]|NAN;}
  JsonArrayConst actions=j["actions"].as<JsonArrayConst>();if(actions.isNull()||actions.size()==0){error="missing_action";return false;}JsonObjectConst a=actions[0];
  if(!a["relayChannel"].is<int>()){error="missing_relay_channel";return false;}
  const int relayChannel=a["relayChannel"].as<int>();
  if(relayChannel<0||relayChannel>=RELAY_COUNT){error="relay_unavailable";return false;}
  c.relayChannel=static_cast<uint8_t>(relayChannel);c.durationSeconds=a["durationSeconds"]|120;
  // A schedule window is authoritative. Recalculate its runtime in firmware so
  // cross-midnight windows do not depend on a possibly stale mobile value.
  if(c.scheduleEnabled&&c.useTimeWindow){
    const uint16_t startMinute=static_cast<uint16_t>(c.hour)*60U+c.minute;
    const uint16_t endMinute=static_cast<uint16_t>(c.endHour)*60U+c.endMinute;
    if(startMinute==endMinute){error="invalid_schedule_window";return false;}
    const uint16_t windowMinutes=endMinute>startMinute?endMinute-startMinute:static_cast<uint16_t>(1440U-startMinute+endMinute);
    c.durationSeconds=static_cast<uint32_t>(windowMinutes)*60UL;
    if(c.durationSeconds>MAX_SCHEDULE_WINDOW_SECONDS){error="schedule_window_too_long";return false;}
  }
  const String fallbackDeviceId=String("relay-")+String(c.relayChannel+1);
  if(j["deviceId"].is<const char*>()){c.deviceId=j["deviceId"].as<String>();}else if(c.deviceId.isEmpty()){c.deviceId=fallbackDeviceId;}
  JsonObjectConst safety=j["safety"];c.maxRuntimeSeconds=safety["maxRuntimeSeconds"]|c.durationSeconds;c.cooldownSeconds=safety["cooldownSeconds"]|300;
  if(c.scheduleEnabled&&c.useTimeWindow&&c.maxRuntimeSeconds<c.durationSeconds)c.maxRuntimeSeconds=c.durationSeconds;
  if(!validate(c,error))return false;int idx=existing;if(idx<0){if(_count>=MAX_SCHEDULE_RULES){error="rule_limit";return false;}idx=_count++;}_rules[idx]=c;if(!_loading){_revision++;save();}return true;
}

int ScheduleAutomationEngine::relayChannelForDevice(const String &deviceId) const {
  const int index = findDevice(deviceId);
  return index < 0 ? -1 : static_cast<int>(_rules[index].relayChannel);
}

bool ScheduleAutomationEngine::removeDevice(const String &deviceId) {
  const int index = findDevice(deviceId);
  if (index < 0) return false;
  return remove(_rules[index].id);
}

bool ScheduleAutomationEngine::remove(const String&id){int i=find(id);if(i<0)return false;if(_rules[i].offAtMs)stopRule(_rules[i],"removed");for(size_t x=i;x+1<_count;x++)_rules[x]=_rules[x+1];_count--;_revision++;save();return true;}
bool ScheduleAutomationEngine::test(const String&id,bool emergency,String&error){int i=find(id);if(i<0){error="rule_not_found";return false;}return execute(_rules[i],emergency,error,true);}

bool ScheduleAutomationEngine::nextRunIso(const ScheduleRule&r,char*buffer,size_t size)const{if(!_clock||!buffer||size<20||!r.enabled||!r.scheduleEnabled||!_clock->snapshot().valid)return false;int32_t best=-1;for(uint8_t d=1;d<=7;d++)if(r.dayMask&(1<<(d-1))){int32_t sec=_clock->secondsUntil(d,r.hour,r.minute);if(sec>=0&&(best<0||sec<best))best=sec;}if(best<0)return false;uint32_t target=_clock->epochLocal()+best,days=target/86400UL,rem=target%86400UL;uint16_t y=1970;while(true){uint16_t dy=((y%4==0&&y%100!=0)||y%400==0)?366:365;if(days<dy)break;days-=dy;y++;}uint8_t m=1;while(true){uint8_t dm=(m==2?(((y%4==0&&y%100!=0)||y%400==0)?29:28):(m==4||m==6||m==9||m==11?30:31));if(days<dm)break;days-=dm;m++;}snprintf(buffer,size,"%04u-%02u-%02uT%02u:%02u:%02u",y,m,(unsigned)(days+1),(unsigned)(rem/3600),(unsigned)((rem%3600)/60),(unsigned)(rem%60));return true;}

void ScheduleAutomationEngine::writeJson(JsonArray a)const{for(size_t i=0;i<_count;i++){const auto&r=_rules[i];JsonObject o=a.add<JsonObject>();o["id"]=r.id;o["name"]=r.name;o["deviceId"]=r.deviceId;o["deviceType"]=r.deviceType;o["controlMode"]=r.controlMode;o["enabled"]=r.enabled;o["priority"]=r.priority;o["conditionLogic"]=r.conditionLogic;JsonObject s=o["trigger"]["schedule"].to<JsonObject>();s["enabled"]=r.scheduleEnabled;s["hour"]=r.hour;s["minute"]=r.minute;s["endHour"]=r.endHour;s["endMinute"]=r.endMinute;s["mode"]=r.useTimeWindow?"window":"at";JsonArray ds=s["daysOfWeek"].to<JsonArray>();for(int d=1;d<=7;d++)if(r.dayMask&(1<<(d-1)))ds.add(d);JsonArray cs=o["conditions"].to<JsonArray>();for(uint8_t n=0;n<r.conditionCount;n++){const auto&c=r.conditions[n];JsonObject x=cs.add<JsonObject>();x["type"]=c.type;x["sensorId"]=c.sensorId;x["metric"]=c.metric;x["operator"]=c.op;x["value"]=c.value;if(!isnan(c.valueHigh))x["valueHigh"]=c.valueHigh;}JsonObject ac=o["actions"].to<JsonArray>().add<JsonObject>();ac["type"]="relay_pulse";ac["relayChannel"]=r.relayChannel;ac["durationSeconds"]=r.durationSeconds;JsonObject sf=o["safety"].to<JsonObject>();sf["maxRuntimeSeconds"]=r.maxRuntimeSeconds;sf["cooldownSeconds"]=r.cooldownSeconds;o["runtimeState"]=stateName(r.runtimeState);o["requestedOn"]=r.requestedOn;o["running"]=r.offAtMs!=0;o["waitingReason"]=r.waitingReason;o["activeReason"]=r.activeReason;o["lastResult"]=r.lastResult;o["lastExecutionKey"]=r.lastExecutionKey;char next[24];if(nextRunIso(r,next,sizeof(next)))o["nextRunAt"]=next;else o["nextRunAt"]=nullptr;}}
void ScheduleAutomationEngine::writeRuntimeJson(JsonArray a)const{for(size_t i=0;i<_count;i++){const auto&r=_rules[i];JsonObject o=a.add<JsonObject>();o["deviceId"]=r.deviceId;o["ruleId"]=r.id;o["relayChannel"]=r.relayChannel;o["requestedState"]=r.requestedOn?"on":"off";o["actualRelayState"]=_relays&&_relays->get(r.relayChannel)?"on":"off";o["runtimeState"]=stateName(r.runtimeState);o["waitingReason"]=r.waitingReason;o["activeReason"]=r.activeReason;o["remainingSeconds"]=r.offAtMs&&((int32_t)(r.offAtMs-millis())>0)?(r.offAtMs-millis())/1000UL:0;}}
void ScheduleAutomationEngine::save(){if(!_prefs)return;JsonDocument d;JsonArray a=d.to<JsonArray>();writeJson(a);String out;serializeJson(d,out);_prefs->putString("scheduleRules",out);_prefs->putUInt("autoRevision",_revision);}
void ScheduleAutomationEngine::load(){
  _count=0;
  _quarantinedRelayMask=0;
  if(!_prefs)return;
  _revision=_prefs->getUInt("autoRevision",1);
  String raw=_prefs->getString("scheduleRules","");
  if(raw.isEmpty())return;
  JsonDocument d;
  if(deserializeJson(d,raw))return;
  _loading=true;
  for(JsonObject o:d.as<JsonArray>()){
    JsonArrayConst actions=o["actions"].as<JsonArrayConst>();
    if(!actions.isNull()&&actions.size()>0){
      JsonObjectConst a=actions[0];
      if(a["relayChannel"].is<int>()){
        const int rawChannel=a["relayChannel"].as<int>();
        if(rawChannel>=0&&rawChannel<RELAY_COUNT){
          _quarantinedRelayMask|=(1UL<<rawChannel);
        }
      }
    }
    String e;
    if(upsertFromJson(o,e)){
      const int loaded=find(String(o["id"]|""));
      if(loaded>=0&&_rules[loaded].relayChannel<32){
        _quarantinedRelayMask&=~(1UL<<_rules[loaded].relayChannel);
      }
    }else if(_events){
      _events->add("automation_quarantine",String("Invalid profile held safe: ")+e,
                   String(o["deviceId"]|""));
    }
  }
  _loading=false;
}
