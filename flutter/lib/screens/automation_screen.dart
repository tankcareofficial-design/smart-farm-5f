import 'package:flutter/material.dart';

import '../controllers/smart_farm_controller.dart';
import '../models/automation_rule.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key, required this.controller});
  final SmartFarmController controller;

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _refresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    await Future.wait<void>([
      widget.controller.refreshAutomationRules(),
      widget.controller.refreshClock(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final clockReady = c.clock.available && c.clock.valid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('เงื่อนไขและเวลา'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'โหลดข้อมูลใหม่',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: c.connected && clockReady ? () => _create(context) : null,
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มตาราง'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _ClockCard(controller: c),
            const SizedBox(height: 12),
            _SafetyHint(clockReady: clockReady, connected: c.connected),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ตารางของอุปกรณ์',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Text('${c.automationRules.length} รายการ'),
              ],
            ),
            const SizedBox(height: 8),
            if (c.automationRules.isEmpty)
              const _EmptyState()
            else
              ...c.automationRules.map(
                (rule) => _RuleCard(rule: rule, controller: c),
              ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final rule = await Navigator.of(context).push<AutomationRule>(
      MaterialPageRoute(builder: (_) => const AutomationRuleEditorScreen()),
    );
    if (rule == null || !context.mounted) {
      return;
    }
    final saved = await widget.controller.saveAutomationRule(rule);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'บันทึกตารางแล้ว' : 'บันทึกไม่สำเร็จ')),
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({required this.controller});
  final SmartFarmController controller;

  @override
  Widget build(BuildContext context) {
    final clock = controller.clock;
    final ready = clock.available && clock.valid;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(
                ready ? Icons.schedule_rounded : Icons.schedule_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'DS3231',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(ready: ready),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ready
                        ? '${_date(clock.dateTimeLocal)} • ${_time(clock.dateTimeLocal)}'
                        : clock.lostPower
                        ? 'ถ่านสำรองหรือเวลาของ RTC ต้องตรวจสอบ'
                        : 'ยังอ่านเวลาจาก RTC ไม่ได้',
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ready
                        ? 'ใช้เวลานี้ควบคุมตาราง แม้อินเทอร์เน็ตไม่พร้อม'
                        : 'ระบบตามเวลาจะถูกพักเพื่อความปลอดภัย',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: controller.connected ? controller.syncClock : null,
              tooltip: 'ซิงค์จากเวลาของโทรศัพท์',
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime? value) => value == null
      ? '--:--:--'
      : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';

  static String _date(DateTime? value) => value == null
      ? '--/--/----'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.ready});
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = ready ? colors.primary : colors.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ready ? 'พร้อมใช้งาน' : 'ไม่พร้อม',
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SafetyHint extends StatelessWidget {
  const _SafetyHint({required this.clockReady, required this.connected});
  final bool clockReady;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final message = !connected
        ? 'เชื่อมต่อกล่องควบคุมก่อนเพิ่มหรือแก้ไขตาราง'
        : !clockReady
        ? 'เวลา RTC ไม่ถูกต้อง ระบบจะไม่เปิดอุปกรณ์ตามตาราง'
        : 'แต่ละตารางมีระยะเวลาสูงสุดและช่วงพัก ป้องกันรีเลย์เปิดค้างหรือทำงานถี่เกินไป';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 20),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.account_tree_outlined, size: 60),
          SizedBox(height: 14),
          Text(
            'ยังไม่มีตารางอัตโนมัติ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'เลือกอุปกรณ์ เวลา วันทำงาน และระยะเวลาได้ในขั้นตอนเดียว',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.controller});
  final AutomationRule rule;
  final SmartFarmController controller;

  @override
  Widget build(BuildContext context) {
    final next = rule.nextRunAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  rule.running
                      ? Icons.play_circle_fill_rounded
                      : Icons.schedule_rounded,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'รีเลย์ ${rule.relayChannel + 1} • ${_days(rule.daysOfWeek)}',
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.enabled,
                  onChanged: (value) => controller.saveAutomationRule(
                    rule.copyWith(enabled: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.schedule,
                  label: _clock(rule.hour, rule.minute),
                ),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: _duration(rule.durationSeconds),
                ),
                _InfoChip(
                  icon: Icons.update_rounded,
                  label: next == null
                      ? 'รอคำนวณครั้งถัดไป'
                      : 'ครั้งถัดไป ${_next(next)}',
                ),
              ],
            ),
            if (rule.lastResult != null && rule.lastResult!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'สถานะล่าสุด: ${rule.lastResult}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: controller.emergencyLatched
                      ? null
                      : () => controller.testAutomationRule(rule.id),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('ทดสอบ'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('ลบ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบตารางนี้หรือไม่'),
        content: Text(rule.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteAutomationRule(rule.id);
  }

  static String _clock(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  static String _duration(int seconds) =>
      seconds % 60 == 0 ? '${seconds ~/ 60} นาที' : '$seconds วินาที';
  static String _next(DateTime value) =>
      '${value.day}/${value.month} ${_clock(value.hour, value.minute)}';
  static String _days(Set<int> days) {
    if (days.length == 7) return 'ทุกวัน';
    const labels = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    final sorted = days.toList()..sort();
    return sorted.map((day) => labels[day - 1]).join(' ');
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 16), const SizedBox(width: 5), Text(label)],
    ),
  );
}

class AutomationRuleEditorScreen extends StatefulWidget {
  const AutomationRuleEditorScreen({super.key});

  @override
  State<AutomationRuleEditorScreen> createState() =>
      _AutomationRuleEditorScreenState();
}

class _AutomationRuleEditorScreenState
    extends State<AutomationRuleEditorScreen> {
  final name = TextEditingController(text: 'รดน้ำตามเวลา');
  TimeOfDay time = const TimeOfDay(hour: 6, minute: 0);
  int relay = 0;
  int minutes = 20;
  int cooldownMinutes = 5;
  final days = <int>{1, 2, 3, 4, 5, 6, 7};

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('เพิ่มตารางอุปกรณ์')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _StepTitle(number: 1, title: 'เลือกอุปกรณ์'),
        DropdownButtonFormField<int>(
          initialValue: relay,
          decoration: const InputDecoration(labelText: 'อุปกรณ์ที่ควบคุม'),
          items: List.generate(
            8,
            (i) => DropdownMenuItem(value: i, child: Text('รีเลย์ ${i + 1}')),
          ),
          onChanged: (value) => setState(() => relay = value ?? 0),
        ),
        const SizedBox(height: 18),
        const _StepTitle(number: 2, title: 'ตั้งเวลาและวันที่ทำงาน'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('เวลาเริ่ม'),
          subtitle: Text(time.format(context)),
          trailing: const Icon(Icons.schedule_rounded),
          onTap: () async {
            final value = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (value != null) setState(() => time = value);
          },
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(7, (i) {
            final day = i + 1;
            return FilterChip(
              label: Text(const ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'][i]),
              selected: days.contains(day),
              onSelected: (selected) =>
                  setState(() => selected ? days.add(day) : days.remove(day)),
            );
          }),
        ),
        const SizedBox(height: 18),
        const _StepTitle(number: 3, title: 'กำหนดระยะเวลาปลอดภัย'),
        DropdownButtonFormField<int>(
          initialValue: minutes,
          decoration: const InputDecoration(labelText: 'เปิดอุปกรณ์นาน'),
          items: const [1, 5, 10, 15, 20, 30, 60]
              .map((v) => DropdownMenuItem(value: v, child: Text('$v นาที')))
              .toList(),
          onChanged: (value) => setState(() => minutes = value ?? 20),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: cooldownMinutes,
          decoration: const InputDecoration(labelText: 'ช่วงพักก่อนทำงานซ้ำ'),
          items: const [1, 5, 10, 15, 30, 60]
              .map((v) => DropdownMenuItem(value: v, child: Text('$v นาที')))
              .toList(),
          onChanged: (value) => setState(() => cooldownMinutes = value ?? 5),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'ชื่อตาราง'),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: days.isEmpty ? null : _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('บันทึกตาราง'),
        ),
      ],
    ),
  );

  void _save() {
    final id = 'rule-${DateTime.now().millisecondsSinceEpoch}';
    Navigator.pop(
      context,
      AutomationRule(
        id: id,
        name: name.text.trim().isEmpty ? 'การทำงานอัตโนมัติ' : name.text.trim(),
        deviceId: 'relay-${relay + 1}',
        enabled: true,
        hour: time.hour,
        minute: time.minute,
        daysOfWeek: Set<int>.from(days),
        relayChannel: relay,
        action: 'relay_pulse',
        durationSeconds: minutes * 60,
        maxRuntimeSeconds: minutes * 60,
        cooldownSeconds: cooldownMinutes * 60,
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.number, required this.title});
  final int number;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        CircleAvatar(radius: 13, child: Text('$number')),
        const SizedBox(width: 9),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}
