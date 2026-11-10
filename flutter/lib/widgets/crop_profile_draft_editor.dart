import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../models/crop_profile.dart';
import '../models/crop_profile_draft.dart';

/// Local draft editor only: no Controller, relay, or NVS calls.
class CropProfileDraftEditor extends StatefulWidget {
  const CropProfileDraftEditor({
    super.key,
    required this.profile,
    required this.initial,
  });
  final CropProfile profile;
  final CropProfileDraft initial;

  @override
  State<CropProfileDraftEditor> createState() => _CropProfileDraftEditorState();
}

class _CropProfileDraftEditorState extends State<CropProfileDraftEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _minTemp;
  late final TextEditingController _maxTemp;
  late final TextEditingController _minHumidity;
  late final TextEditingController _maxHumidity;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _minTemp = TextEditingController(
      text: widget.initial.temperatureMinC?.toString() ?? '',
    );
    _maxTemp = TextEditingController(
      text: widget.initial.temperatureMaxC?.toString() ?? '',
    );
    _minHumidity = TextEditingController(
      text: widget.initial.humidityMinPercent?.toString() ?? '',
    );
    _maxHumidity = TextEditingController(
      text: widget.initial.humidityMaxPercent?.toString() ?? '',
    );
    _note = TextEditingController(text: widget.initial.note);
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _minTemp, _maxTemp, _minHumidity, _maxHumidity, _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _value(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  void _save() {
    if (!_form.currentState!.validate()) return;
    final a = _value(_minTemp);
    final b = _value(_maxTemp);
    final c = _value(_minHumidity);
    final d = _value(_maxHumidity);
    if ((a != null && b != null && a > b) ||
        (c != null && d != null && c > d)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.text(
            'ค่าต่ำสุดต้องไม่มากกว่าค่าสูงสุด',
            'Minimum must not exceed maximum',
          )),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      CropProfileDraft(
        cropId: widget.profile.id,
        temperatureMinC: a,
        temperatureMaxC: b,
        humidityMinPercent: c,
        humidityMaxPercent: d,
        note: _note.text.trim(),
      ),
    );
  }

  String? _validate(String? text, double min, double max) {
    final v = text?.trim() ?? '';
    if (v.isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null || !n.isFinite || n < min || n > max) {
      return context.l10n.text(
        'กรอกตัวเลขในช่วง $min ถึง $max',
        'Enter a value from $min to $max',
      );
    }
    return null;
  }

  Widget _field(
    String keyName,
    TextEditingController controller,
    String label,
    double min,
    double max,
  ) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          key: Key(keyName),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          validator: (value) => _validate(value, min, max),
          decoration: InputDecoration(
            labelText: label,
            hintText: context.l10n.text('ยังไม่กำหนด', 'Not set'),
            border: const OutlineInputBorder(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18, 18, 18, MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Form(
          key: _form,
          child: ListView(
            key: const Key('crop-draft-editor'),
            shrinkWrap: true,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.text('ปรับแต่งพรีเซ็ต', 'Customize preset'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: l10n.text('ปิด', 'Close'),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.text(
                'บันทึกเป็นแบบร่างในโทรศัพท์ ไม่สั่งปั๊ม รีเลย์ หรือระบบอัตโนมัติ',
                'Phone-only draft: does not command pumps, relays, or automation.',
              )),
              const SizedBox(height: 18),
              _field(
                'crop-temperature-min', _minTemp,
                l10n.text('อุณหภูมิต่ำสุด (°C)', 'Minimum temperature (°C)'),
                -50, 100,
              ),
              _field(
                'crop-temperature-max', _maxTemp,
                l10n.text('อุณหภูมิสูงสุด (°C)', 'Maximum temperature (°C)'),
                -50, 100,
              ),
              _field(
                'crop-humidity-min', _minHumidity,
                l10n.text('ความชื้นอากาศต่ำสุด (%)', 'Minimum air humidity (%)'),
                0, 100,
              ),
              _field(
                'crop-humidity-max', _maxHumidity,
                l10n.text('ความชื้นอากาศสูงสุด (%)', 'Maximum air humidity (%)'),
                0, 100,
              ),
              TextFormField(
                key: const Key('crop-custom-note'),
                controller: _note,
                maxLength: 240,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.text(
                    'หมายเหตุการปรับแต่ง (ไม่บังคับ)',
                    'Customization note (optional)',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('crop-draft-reset'),
                      onPressed: () => Navigator.pop(
                        context,
                        CropProfileDraft(cropId: widget.profile.id),
                      ),
                      child: Text(l10n.text('คืนค่าเดิม', 'Reset preset')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const Key('crop-draft-save'),
                      onPressed: _save,
                      child: Text(l10n.text('บันทึกแบบร่าง', 'Save draft')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
