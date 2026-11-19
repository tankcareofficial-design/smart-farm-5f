import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../models/crop_profile.dart';
import '../models/crop_profile_draft.dart';

/// Shows sourced growing recommendations, not autonomous device thresholds.
class CropReferenceValues extends StatelessWidget {
  const CropReferenceValues({
    super.key,
    required this.profile,
    required this.draft,
  });

  final CropProfile profile;
  final CropProfileDraft draft;

  String _number(double? value) {
    if (value == null) return '—';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  String _range(double? min, double? max, {String suffix = ''}) {
    if (min == null || max == null) return '';
    return '${_number(min)}–${_number(max)}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final climate = profile.referenceClimate;
    final airTemperature = _range(
      draft.temperatureMinC,
      draft.temperatureMaxC,
      suffix: ' °C',
    );
    final airHumidity = _range(
      draft.humidityMinPercent,
      draft.humidityMaxPercent,
      suffix: '%',
    );
    final manuallyAdjusted = draft.isCustomized(profile);
    final sourceName = climate.sourceTitle(isThai: l10n.isThai);
    final scope = climate.context(isThai: l10n.isThai);
    final label = l10n.text('ยังไม่กำหนด', 'Not set');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.text('ชุดค่าแนะนำที่เลือก', 'Selected recommended values'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              manuallyAdjusted
                  ? l10n.text('มีการปรับแต่ง', 'Customized')
                  : climate.hasTemperatureRange
                      ? l10n.text('ค่าตั้งต้นจากแหล่งวิชาการ', 'Source-backed defaults')
                      : l10n.text('ยังไม่มีค่าตั้งต้นที่ยืนยันแล้ว', 'No verified starting values yet'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            _MetricRow(
              label: l10n.text('อุณหภูมิอากาศ', 'Air temperature'),
              value: airTemperature.isEmpty ? label : airTemperature,
            ),
            const Divider(height: 20),
            _MetricRow(
              label: l10n.text('ความชื้นอากาศ', 'Air humidity'),
              value: airHumidity.isEmpty ? label : airHumidity,
            ),
            const Divider(height: 20),
            _MetricRow(
              label: l10n.text('ความชื้นดิน / เวลาปั๊ม', 'Soil moisture / pump timing'),
              value: l10n.text('ต้องสอบเทียบและตั้งค่าเอง', 'Requires local calibration'),
            ),
            if (climate.hasTemperatureRange) ...<Widget>[
              const SizedBox(height: 8),
              ExpansionTile(
                key: const Key('crop-reference-source'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(l10n.text('ดูที่มาของค่าแนะนำ', 'View source')),
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(sourceName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(scope),
                        const SizedBox(height: 6),
                        SelectableText(climate.sourceUrl),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
}
