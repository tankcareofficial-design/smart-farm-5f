import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../data/crop_profile_catalog.dart';
import '../models/irrigation_simulation.dart';
import '../models/irrigation_zone_plan.dart';

/// Demonstrates controller decisions on the phone. No device or API imports.
class IrrigationSimulationScreen extends StatefulWidget {
  const IrrigationSimulationScreen({super.key, required this.plan});

  final IrrigationPlan plan;

  @override
  State<IrrigationSimulationScreen> createState() =>
      _IrrigationSimulationScreenState();
}

class _IrrigationSimulationScreenState
    extends State<IrrigationSimulationScreen> {
  final Map<String, double?> _mockMoisture = <String, double?>{};
  String? _activeZoneId;
  bool _emergencyStop = false;

  @override
  void initState() {
    super.initState();
    for (final zone in widget.plan.zones) {
      _mockMoisture[zone.id] = 50;
    }
  }

  IrrigationSimulationResult _evaluate({
    String? previousActiveZoneId,
    bool? emergencyStop,
  }) => IrrigationSimulationEngine.evaluate(
    plan: widget.plan,
    moistureByZone: _mockMoisture,
    previousActiveZoneId: previousActiveZoneId ?? _activeZoneId,
    emergencyStop: emergencyStop ?? _emergencyStop,
  );

  void _changeReading(String zoneId, double? value) {
    setState(() {
      _mockMoisture[zoneId] = value;
      _activeZoneId = _evaluate().activeZoneId;
    });
  }

  void _changeStop(bool value) {
    setState(() {
      _emergencyStop = value;
      _activeZoneId = _evaluate(emergencyStop: value).activeZoneId;
    });
  }

  void _reset() {
    setState(() {
      for (final zone in widget.plan.zones) {
        _mockMoisture[zone.id] = 50;
      }
      _emergencyStop = false;
      _activeZoneId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = _evaluate();
    final activeZone = widget.plan.zones
        .where((zone) => zone.id == result.activeZoneId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('ทดลองสมองดูแลพืช', 'Care logic simulator')),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.text('เริ่มจำลองใหม่', 'Reset simulation'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reset,
          ),
        ],
      ),
      body: ListView(
        key: const Key('irrigation-simulation-list'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Card(
            color: const Color(0xFFEAF4E7),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.science_outlined, color: Color(0xFF276A34)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.text(
                        'ห้องทดลองในโทรศัพท์เท่านั้น เลื่อนค่าความชื้นเพื่อดูว่าระบบจะเลือกให้น้ำโซนใด ไม่มีการอ่านเซ็นเซอร์หรือสั่งรีเลย์จริง',
                        'Phone-only demo. Move mock moisture sliders to see which zone would request water. No real sensors or relay commands.',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.text('ตัวอย่างค่าตัดสินใจ', 'Illustrative thresholds'),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.text(
                      'เริ่มขอน้ำเมื่อความชื้นไม่เกิน 45% และหยุดเมื่อถึง 55%',
                      'Request water at 45% or below; stop at 55% or above',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.text(
                      '45/55% เป็นตัวเลขจำลอง ไม่ใช่ค่าที่แนะนำสำหรับผักบุ้งหรือผักชนิดใด ต้องสอบเทียบเซ็นเซอร์และดินจริงก่อนใช้ควบคุม',
                      '45/55% are demo values, not crop recommendations. Real soil sensor and growing media must be calibrated first.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            key: const Key('simulation-emergency-stop'),
            value: _emergencyStop,
            activeTrackColor: const Color(0xFFB3463D),
            title: Text(l10n.text('จำลองปุ่มหยุดฉุกเฉิน', 'Simulate emergency stop')),
            subtitle: Text(l10n.text(
              'หยุดคำขอน้ำทั้งหมดในแบบจำลอง',
              'Block all simulated water requests',
            )),
            onChanged: _changeStop,
          ),
          Card(
            child: ListTile(
              key: const Key('simulation-pump-status'),
              leading: Icon(
                result.pumpWouldRun ? Icons.water_drop_rounded :
                    Icons.water_drop_outlined,
                color: result.pumpWouldRun
                    ? const Color(0xFF237F45) : Colors.grey,
              ),
              title: Text(
                widget.plan.delivery == WaterDelivery.valveOnly
                    ? l10n.text(
                        'แบบใช้วาล์ว ไม่ต้องสั่งปั๊ม',
                        'Valve-only plan, no pump requested',
                      )
                    : result.pumpWouldRun
                        ? l10n.text(
                            'จำลอง: ต้องการเปิดปั๊ม',
                            'Simulation: pump would be requested',
                          )
                        : l10n.text(
                            'จำลอง: ยังไม่ต้องเปิดปั๊ม',
                            'Simulation: pump would remain off',
                          ),
              ),
              subtitle: Text(
                _emergencyStop
                    ? l10n.text('โหมดหยุดฉุกเฉินจำลอง', 'Simulated emergency stop')
                    : activeZone == null
                        ? l10n.text(
                            'ไม่มีโซนที่ต้องการน้ำในขณะนี้',
                            'No zone currently requests water',
                          )
                        : l10n.text(
                            'เลือกให้น้ำ ${activeZone.name} ก่อน · โซนอื่นรอคิว',
                            'Serve ${activeZone.name} first; other zones wait',
                          ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.text('ลองปรับความชื้นแต่ละโซน', 'Try each zone moisture'),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.text(
              'ทั้งสองโซนอาจปลูกผักชนิดเดียวกันได้ โดยตั้งค่าคนละโซน',
              'Zones can grow the same crop and still behave independently.',
            ),
          ),
          const SizedBox(height: 10),
          for (final zone in widget.plan.zones)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _zoneCard(zone, result),
            ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            key: const Key('simulation-reset'),
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.text('เริ่มทดลองใหม่', 'Reset demo')),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.text(
              'ผลข้างต้นคือความต้องการน้ำในเชิงตรรกะ ไม่ได้จำลองจังหวะเปิดวาล์วก่อนปั๊ม การตรวจอัตราการไหล หรือระบบความปลอดภัยทั้งหมด',
              'Logical demand only. This does not model valve/pump switching sequences, water flow or complete safety interlocks.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _zoneCard(IrrigationZone zone, IrrigationSimulationResult result) {
    final crop = CropProfileCatalog.byId(zone.cropId);
    final reading = _mockMoisture[zone.id];
    final selected = result.activeZoneId == zone.id;
    final waiting = result.waitingZoneIds.contains(zone.id);
    final label = _emergencyStop
        ? context.l10n.text('หยุดฉุกเฉิน', 'Emergency stop')
        : reading == null
            ? context.l10n.text('ไม่มีข้อมูลจำลอง', 'No mock reading')
            : selected
                ? context.l10n.text('จำลอง: ให้น้ำโซนนี้', 'Simulated watering')
                : waiting
                    ? context.l10n.text('รอคิวปั๊มร่วม', 'Waiting for pump')
                    : context.l10n.text('ยังไม่ต้องให้น้ำ', 'Water not needed');

    return Card(
      key: Key('simulation-zone-${zone.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: const Color(0xFFE3F3E5),
                  child: Icon(Icons.spa_rounded, color: selected
                      ? const Color(0xFF23813B) : const Color(0xFF467752)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(zone.name,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(crop?.name(isThai: context.l10n.isThai) ?? zone.cropId,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(reading == null ? '—' : '${reading.round()}%',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Slider(
              key: Key('simulation-moisture-${zone.id}'),
              value: reading ?? 50,
              min: 0,
              max: 100,
              divisions: 100,
              label: reading == null ? null : '${reading.round()}%',
              onChanged: _emergencyStop
                  ? null : (value) => _changeReading(zone.id, value),
            ),
            Row(
              children: <Widget>[
                Icon(
                  selected ? Icons.water_drop_rounded : Icons.info_outline,
                  size: 17,
                  color: selected ? const Color(0xFF237F45) : Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(label,
                    key: Key('simulation-status-${zone.id}'))),
                TextButton(
                  key: Key('simulation-dry-${zone.id}'),
                  onPressed: _emergencyStop ? null
                      : () => _changeReading(zone.id, 30),
                  child: Text(context.l10n.text('ลองดินแห้ง', 'Try dry')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
