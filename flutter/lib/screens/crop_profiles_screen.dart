import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../data/crop_profile_catalog.dart';
import '../models/crop_profile.dart';

/// Preview-only offline catalog: intentionally contains no Controller calls.
class CropProfilesScreen extends StatefulWidget {
  const CropProfilesScreen({super.key});

  @override
  State<CropProfilesScreen> createState() => _CropProfilesScreenState();
}

class _CropProfilesScreenState extends State<CropProfilesScreen> {
  String _query = '';
  CropGroup? _group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final crops = CropProfileCatalog.search(_query)
        .where((crop) => _group == null || crop.group == _group)
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.text('พรีเซ็ตพืชผัก', 'Crop presets'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        key: const Key('crop-profile-list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: <Widget>[
          _Notice(
            text: l10n.text(
              'ตัวอย่างพรีเซ็ต: ยังไม่สั่งปั๊ม รีเลย์ หรือบันทึกค่าไปยัง Controller',
              'Preset preview: no pump/relay commands or controller writes.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('crop-profile-search'),
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              labelText: l10n.text('ค้นหาชนิดผัก', 'Search crops'),
              prefixIcon: const Icon(Icons.search_rounded),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _filterChip(context, null),
                for (final g in CropGroup.values) _filterChip(context, g),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.text(
              'พบ ${crops.length} รายการ',
              '${crops.length} crops',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          if (crops.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(l10n.text('ไม่พบพืชที่ค้นหา', 'No matching crops')),
              ),
            ),
          for (final crop in crops) ...<Widget>[
            Card(
              child: ListTile(
                key: Key('crop-profile-${crop.id}'),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(child: Icon(_icon(crop.group))),
                title: Text(
                  crop.name(isThai: l10n.isThai),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(_groupName(context, crop.group)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => CropProfileDetailScreen(profile: crop),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, CropGroup? value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(
            value == null
                ? context.l10n.text('ทั้งหมด', 'All')
                : _groupName(context, value),
          ),
          selected: _group == value,
          onSelected: (_) => setState(() => _group = value),
        ),
      );
}

class CropProfileDetailScreen extends StatelessWidget {
  const CropProfileDetailScreen({super.key, required this.profile});

  final CropProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(profile.name(isThai: l10n.isThai))),
      body: ListView(
        key: const Key('crop-profile-detail'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 26,
                    child: Icon(_icon(profile.group), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profile.name(isThai: l10n.isThai),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_groupName(context, profile.group)} · Crop Profile v${profile.schemaVersion}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Notice(
            text: l10n.text(
              'ยังไม่พร้อมควบคุมอุปกรณ์: ต้องตรวจแหล่งข้อมูล สอบเทียบเซนเซอร์และวัสดุปลูก และยืนยันขีดจำกัดปั๊มก่อน',
              'Not ready for automatic control: verify references, calibrate sensors/media, and validate pump limits first.',
            ),
          ),
          const SizedBox(height: 16),
          _GuidanceCard(
            icon: Icons.water_drop_outlined,
            title: l10n.text('แนวทางให้น้ำ', 'Watering guidance'),
            description: profile.waterNote(isThai: l10n.isThai),
          ),
          const SizedBox(height: 8),
          _GuidanceCard(
            icon: Icons.wb_sunny_outlined,
            title: l10n.text('แสงและสภาพแวดล้อม', 'Light and environment'),
            description: profile.lightNote(isThai: l10n.isThai),
          ),
          const SizedBox(height: 8),
          _GuidanceCard(
            icon: Icons.tune_rounded,
            title: l10n.text('ค่าเป้าหมายสำหรับควบคุม', 'Control targets'),
            description: l10n.text(
              'อุณหภูมิ ความชื้นดิน ความชื้นอากาศ เวลาเดินปั๊ม และเวลาพักปั๊ม: ยังไม่กำหนด',
              'Temperature, soil/air humidity, pump runtime and cooldown: unset.',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('crop-apply-disabled'),
            onPressed: null,
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(
              l10n.text(
                'ใช้งานกับ Controller (ยังไม่เปิดใช้)',
                'Apply to controller (not yet enabled)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(description),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

String _groupName(BuildContext context, CropGroup group) => switch (group) {
      CropGroup.leafy => context.l10n.text('ผักใบ', 'Leafy'),
      CropGroup.herb => context.l10n.text('สมุนไพร', 'Herbs'),
      CropGroup.fruiting => context.l10n.text('พืชให้ผล', 'Fruiting'),
      CropGroup.custom => context.l10n.text('กำหนดเอง', 'Custom'),
    };

IconData _icon(CropGroup group) => switch (group) {
      CropGroup.leafy => Icons.eco_rounded,
      CropGroup.herb => Icons.spa_rounded,
      CropGroup.fruiting => Icons.local_florist_rounded,
      CropGroup.custom => Icons.tune_rounded,
    };
