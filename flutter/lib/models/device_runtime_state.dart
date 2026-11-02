enum DeviceRuntimeStatus { off, waiting, running, blocked, override, error }

class DeviceRuntimeState {
  const DeviceRuntimeState({
    required this.deviceId,
    required this.ruleId,
    required this.relayChannel,
    required this.requestedOn,
    required this.actualOn,
    required this.status,
    this.waitingReason = '',
    this.activeReason = '',
    this.remainingSeconds = 0,
  });
  final String deviceId;
  final String ruleId;
  final int relayChannel;
  final bool requestedOn;
  final bool actualOn;
  final DeviceRuntimeStatus status;
  final String waitingReason;
  final String activeReason;
  final int remainingSeconds;
  factory DeviceRuntimeState.fromJson(Map<String, dynamic> j) =>
      DeviceRuntimeState(
        deviceId: j['deviceId']?.toString() ?? '',
        ruleId: j['ruleId']?.toString() ?? '',
        relayChannel: (j['relayChannel'] as num?)?.toInt() ?? 0,
        requestedOn: j['requestedState'] == 'on',
        actualOn: j['actualRelayState'] == 'on',
        status: DeviceRuntimeStatus.values.firstWhere(
          (e) => e.name == j['runtimeState'],
          orElse: () => DeviceRuntimeStatus.off,
        ),
        waitingReason: j['waitingReason']?.toString() ?? '',
        activeReason: j['activeReason']?.toString() ?? '',
        remainingSeconds: (j['remainingSeconds'] as num?)?.toInt() ?? 0,
      );
}
