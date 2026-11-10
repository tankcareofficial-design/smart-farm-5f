import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../data/crop_profile_catalog.dart';
import '../models/irrigation_zone_plan.dart';
import '../services/irrigation_zone_repository.dart';

/// Phone-local zone planning only. Never sends commands to the control box.
class IrrigationZonesScreen extends StatefulWidget {
  const IrrigationZonesScreen({
    super.key,
    this.existingDeviceChannels = const <int>{},
  });
  final Set<int> existingDeviceChannels;

  @override
  State<IrrigationZonesScreen> createState() => _IrrigationZonesScreenState();
}

class _IrrigationZonesScreenState extends State<IrrigationZonesScreen> {
  final _repository = IrrigationZoneRepository();
  IrrigationPlan _plan = IrrigationPlan.firstUse();
  bool _loading = true;
  Future<void> _writeQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final draft = await _repository.load();
    if (mounted) {
      setState(() {
        _plan = draft;
        _loading = false;
      });
    }
  }

  void _change(IrrigationPlan draft) {
    setState(() => _plan = draft);
    _writeQueue = _writeQueue.then((_) async {
      try {
        if (await _repository.save(draft)) return;
      } catch (_) {
        // Keep the UI usable even if local persistence fails.
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text(
            'บันทึกแผนในโทรศัพท์ไม่สำเร็จ',
            'Could not save this phone-only plan',
          ))),
        );
      }
    });
  }

  void _editZone(IrrigationZone edited) {
    _change(_plan.copyWith(
      zones: _plan.zones
          .map((zone) => zone.id == edited.id ? edited : zone)
          .toList(growable: false),
    ));
  }

  void _addZone() {
    if (_plan.zones.length >=
        (_plan.delivery == WaterDelivery.valveOnly ? 8 : 7)) {
      return;
    }
    var index = 1;
    while (_plan.zones.any((zone) => zone.id == 'zone-$index')) {
      index++;
    }
    final requiresValves = _plan.delivery == WaterDelivery.pumpDirect;
    _change(_plan.copyWith(
      delivery: requiresValves ? WaterDelivery.sharedPumpValves : null,
      zones: <IrrigationZone>[
        ..._plan.zones,
        IrrigationZone(id: 'zone-$index', name: 'โซน $index', cropId: 'water_spinach'),
      ],
    ));
    if (requiresValves) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text(
          'เพิ่มโซนแล้ว: ใช้ปั๊มร่วมและวาล์วแยกแต่ละโซนในแผนนี้',
          'Added a zone: now planning shared pump and separate zone valves',
        ))),
      );
    }
  }

  String _deliveryLabel(WaterDelivery value) => switch (value) {
    WaterDelivery.pumpDirect => context.l10n.text(
      'ปั๊มตรง · โซนเดียว', 'Direct pump · one zone',
    ),
    WaterDelivery.valveOnly => context.l10n.text(
      'วาล์วอย่างเดียว · มีแรงดันน้ำอยู่แล้ว',
      'Valve only · existing water pressure',
    ),
    WaterDelivery.sharedPumpValves => context.l10n.text(
      'ปั๊มร่วม + วาล์วแยกโซน',
      'Shared pump + separate zone valves',
    ),
  };

  String _controlLabel(ZoneControl value) => switch (value) {
    ZoneControl.manual => context.l10n.text('ควบคุมเอง', 'Manual'),
    ZoneControl.schedule => context.l10n.text(
      'ตั้งเวลา (ยังไม่เปิดใช้)', 'Schedule (preview)',
    ),
    ZoneControl.soilMoisture => context.l10n.text(
      'ตามความชื้นดิน (รอเซ็นเซอร์)', 'Soil moisture (sensor required)',
    ),
  };

  String _issueText(IrrigationIssue issue) {
    final th = context.l10n.isThai;
    final zoneName = _plan.zones
        .where((zone) => zone.id == issue.zoneId)
        .map((zone) => zone.name)
        .firstOrNull;
    final prefix = zoneName == null ? '' : '$zoneName · ';
    final description = switch (issue.code) {
      'channel_unassigned' => th ? 'ยังไม่ระบุช่องรีเลย์' : 'Relay channel not selected',
      'channel_duplicate' => th ? 'ช่องรีเลย์ซ้ำกัน' : 'Duplicate relay channel',
      'channel_reserved' => th
          ? 'ช่องรีเลย์นี้ใช้งานกับอุปกรณ์ทั่วไปแล้ว'
          : 'Channel used by a general device',
      'channel_out_of_range' => th
          ? 'ช่องรีเลย์ต้องอยู่ระหว่าง 1–8'
          : 'Channel must be between 1 and 8',
      'direct_pump_one_zone_only' => th
          ? 'ปั๊มตรงใช้ได้เพียงโซนเดียว หากเพิ่มโซนต้องมีวาล์วแยก'
          : 'Direct pump supports one zone; extra zones need separate valves',
      'soil_sensor_unassigned' => th
          ? 'ยังไม่มีเซ็นเซอร์ความชื้นของโซน'
          : 'Soil sensor not assigned',
      'soil_calibration_required' => th
          ? 'ต้องสอบเทียบเซ็นเซอร์กับดินจริง'
          : 'Real soil calibration required',
      'moisture_thresholds_invalid' => th
          ? 'ยังไม่มีช่วงความชื้นที่สอบเทียบแล้ว'
          : 'Calibrated moisture band not set',
      'schedule_not_configured' => th
          ? 'ต้องกำหนดตารางและตรวจนาฬิกา'
          : 'Schedule and controller clock not validated',
      _ => issue.code,
    };
    return '$prefix$description';
  }

  Widget _channelSelect({
    required String keyName,
    required String label,
    required int? channel,
    required ValueChanged<int?> onChanged,
  }) => DropdownButtonFormField<int>(
    key: Key(keyName),
    initialValue: channel ?? 0,
    isExpanded: true,
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      labelText: label,
    ),
    items: <DropdownMenuItem<int>>[
      DropdownMenuItem<int>(
        value: 0,
        child: Text(context.l10n.text('ยังไม่ระบุ', 'Unassigned')),
      ),
      for (var number = 1; number <= 8; number++)
        DropdownMenuItem<int>(value: number, child: Text('CH$number')),
    ],
    onChanged: (number) => onChanged(number == 0 ? null : number),
  );

  Widget _zoneCard(IrrigationZone zone) {
    return Card(
      key: Key('zone-card-${zone.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.spa_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(zone.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (_plan.zones.length > 1)
                  IconButton(
                    key: Key('zone-remove-${zone.id}'),
                    tooltip: context.l10n.text('ลบโซน', 'Remove zone'),
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _change(_plan.copyWith(
                      zones: _plan.zones
                          .where((item) => item.id != zone.id)
                          .toList(growable: false),
                    )),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: Key('zone-crop-${zone.id}'),
              initialValue: CropProfileCatalog.byId(zone.cropId) == null
                  ? 'custom' : zone.cropId,
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: context.l10n.text('เลือกพืช', 'Choose crop'),
              ),
              items: CropProfileCatalog.profiles.map((crop) =>
                  DropdownMenuItem<String>(
                    value: crop.id,
                    child: Text(crop.name(isThai: context.l10n.isThai)),
                  ),
              ).toList(growable: false),
              onChanged: (value) {
                if (value != null) _editZone(zone.copyWith(cropId: value));
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ZoneControl>(
              key: Key('zone-mode-${zone.id}'),
              initialValue: zone.control,
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: context.l10n.text('วิธีควบคุม', 'Control method'),
              ),
              items: ZoneControl.values.map((mode) =>
                  DropdownMenuItem<ZoneControl>(
                    value: mode,
                    child: Text(_controlLabel(mode)),
                  ),
              ).toList(growable: false),
              onChanged: (value) {
                if (value != null) _editZone(zone.copyWith(control: value));
              },
            ),
            if (_plan.delivery != WaterDelivery.pumpDirect) ...<Widget>[
              const SizedBox(height: 12),
              _channelSelect(
                keyName: 'zone-valve-${zone.id}',
                label: context.l10n.text('รีเลย์วาล์วโซน', 'Zone valve relay'),
                channel: zone.valveChannel,
                onChanged: (value) => _editZone(zone.copyWith(
                  valveChannel: value,
                  clearValveChannel: value == null,
                )),
              ),
            ],
            if (zone.control != ZoneControl.manual) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                zone.control == ZoneControl.schedule
                    ? context.l10n.text(
                        'โหมดตั้งเวลาต้องตรวจนาฬิกาก่อนใช้งานจริง',
                        'Schedule requires validated controller time',
                      )
                    : context.l10n.text(
                        'รอเซ็นเซอร์ความชื้นดินและการสอบเทียบก่อนเปิดอัตโนมัติ',
                        'Soil sensor and calibration are required',
                      ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checks = _plan.validate(
      existingDeviceChannels: widget.existingDeviceChannels,
    );
    final count = _plan.zones.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('ออกแบบโซนให้น้ำ', 'Plan watering zones')),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        key: const Key('irrigation-plan-list'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.l10n.text(
                    'ปลูกผักบุ้งโซนเดียวก่อนก็ได้ เพิ่มโซนภายหลังได้ ไม่ต้องซื้ออุปกรณ์ครบ 8 ช่อง แผนนี้บันทึกในโทรศัพท์เท่านั้น',
                    'Start with one water-spinach zone, expand anytime. All 8 channels are not required. Phone-only draft.',
                  ))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<WaterDelivery>(
            key: const Key('irrigation-delivery'),
            initialValue: _plan.delivery,
            isExpanded: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: context.l10n.text(
                'เลือกรูปแบบระบบน้ำ', 'Choose water layout',
              ),
            ),
            items: WaterDelivery.values.map((delivery) =>
                DropdownMenuItem<WaterDelivery>(
                  value: delivery,
                  child: Text(_deliveryLabel(delivery)),
                ),
            ).toList(growable: false),
            onChanged: (value) {
              if (value != null) _change(_plan.copyWith(delivery: value));
            },
          ),
          if (_plan.delivery != WaterDelivery.valveOnly) ...<Widget>[
            const SizedBox(height: 12),
            _channelSelect(
              keyName: 'irrigation-pump-channel',
              label: context.l10n.text('ช่องรีเลย์ปั๊ม', 'Pump relay channel'),
              channel: _plan.pumpChannel,
              onChanged: (channel) => _change(_plan.copyWith(
                pumpChannel: channel,
                clearPumpChannel: channel == null,
              )),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(child: Text(
                context.l10n.text('แผนโซน ($count)', 'Zones ($count)'),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              )),
              TextButton.icon(
                key: const Key('irrigation-add-zone'),
                onPressed: count >=
                    (_plan.delivery == WaterDelivery.valveOnly ? 8 : 7)
                    ? null : _addZone,
                icon: const Icon(Icons.add_rounded),
                label: Text(context.l10n.text('เพิ่มโซน', 'Add zone')),
              ),
            ],
          ),
          for (final zone in _plan.zones) ...<Widget>[
            _zoneCard(zone),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 14),
          Text(context.l10n.text('รายการที่ต้องตรวจ', 'Plan checks'),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (checks.isEmpty)
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(context.l10n.text(
                'แผนครบ แต่ยังไม่ส่งไปกล่องควบคุม',
                'Plan fields complete; not applied to controller',
              )),
            )
          else
            for (final issue in checks.take(6))
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text(_issueText(issue)),
              ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('irrigation-controller-apply-disabled'),
            onPressed: null,
            icon: const Icon(Icons.lock_outline),
            label: Text(context.l10n.text(
              'เริ่มดูแลอัตโนมัติ (ยังไม่เปิดใช้งาน)',
              'Start automatic care (not yet available)',
            )),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.text(
            'ช่องรีเลย์นี้เป็นเพียงแผน ไม่จอง ไม่เปิด และไม่แก้ค่าในกล่องควบคุม',
            'These are planned channels only: no reservations, relay actions or controller changes.',
          ), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
