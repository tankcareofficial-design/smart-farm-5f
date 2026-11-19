import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../models/sensor_config.dart';
import '../stores/sensor_store.dart';

class SensorSetupDialog extends StatefulWidget {
  const SensorSetupDialog({
    super.key,
    required this.store,
    this.existing,
    this.canSave,
  });

  final SensorStore store;
  final SensorConfig? existing;

  /// Recheck connectivity when the form is actually committed, since the
  /// local Controller can disconnect after this sheet has been opened.
  final bool Function()? canSave;

  @override
  State<SensorSetupDialog> createState() => _SensorSetupDialogState();
}

class _SensorSetupDialogState extends State<SensorSetupDialog> {
  late SupportedSensorProfile _profile;
  late String _inputId;
  late final TextEditingController _nameController;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _profile = supportedSensorProfiles.firstWhere(
      (SupportedSensorProfile item) =>
          item.driverKey == widget.existing?.driverKey,
      orElse: () => supportedSensorProfiles.first,
    );
    _inputId = widget.existing?.inputId ?? _profile.recommendedInput;
    _nameController = TextEditingController(
      text: widget.existing?.name ?? _profile.nameTh,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<String> get _inputChoices {
    switch (_profile.busType) {
      case SensorBusType.i2c:
        return const <String>['I2C BUS'];
      case SensorBusType.analog:
        return const <String>['AI1 / GPIO34', 'AI2 / GPIO35'];
      case SensorBusType.digital:
        if (_profile.driverKey == 'jsn_sr04t') {
          return const <String>['DI1 + DI2', 'DI3 + DI4'];
        }
        return const <String>[
          'DI1 / GPIO32',
          'DI2 / GPIO33',
          'DI3 / GPIO25',
          'DI4 / GPIO26',
        ];
    }
  }

  void _selectProfile(SupportedSensorProfile value) {
    setState(() {
      _profile = value;
      _inputId = value.recommendedInput;
      if (!isEditing) {
        _nameController.text = context.l10n.isThai
            ? value.nameTh
            : value.nameEn;
      }
    });
  }

  void _save() {
    if (widget.canSave != null && !widget.canSave!()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('sensor-save-controller-offline-warning'),
          content: Text(context.l10n.text(
            'กล่องควบคุมออฟไลน์: บันทึกเซ็นเซอร์ไม่ได้ กรุณาเชื่อมต่อกล่องควบคุมแล้วลองใหม่',
            'Control box offline: cannot save sensor. Reconnect the control box and retry.',
          )),
        ),
      );
      return;
    }
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final SensorConfig config = SensorConfig(
      id:
          widget.existing?.id ??
          'sensor-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: _profile.type,
      driverKey: _profile.driverKey,
      inputId: _inputId,
      enabled: widget.existing?.enabled ?? true,
    );
    try {
      if (isEditing) {
        widget.store.updateSensor(config);
      } else {
        widget.store.addSensor(config);
      }
      Navigator.of(context).pop();
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.l10n.text(
                          isEditing ? 'แก้ไขเซ็นเซอร์' : 'เพิ่มเซ็นเซอร์',
                          isEditing ? 'Edit sensor' : 'Add sensor',
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.text(
                    'เลือกเซ็นเซอร์ที่รองรับ',
                    'Choose a supported sensor',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<SupportedSensorProfile>(
                  initialValue: _profile,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: supportedSensorProfiles.map((
                    SupportedSensorProfile item,
                  ) {
                    return DropdownMenuItem<SupportedSensorProfile>(
                      value: item,
                      child: Text(
                        context.l10n.isThai ? item.nameTh : item.nameEn,
                      ),
                    );
                  }).toList(),
                  onChanged: (SupportedSensorProfile? value) {
                    if (value != null) _selectProfile(value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.text('ชื่อที่แสดง', 'Display name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.text('เลือก INPUT', 'Choose INPUT'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _inputChoices.contains(_inputId)
                      ? _inputId
                      : _inputChoices.first,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _inputChoices
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _inputId = value);
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.cable_rounded,
                            color: colors.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.text(
                              'คำแนะนำการต่อสาย',
                              'Wiring guide',
                            ),
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        context.l10n.isThai
                            ? _profile.wiringTh
                            : _profile.wiringEn,
                        style: TextStyle(color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${context.l10n.text('INPUT ที่แนะนำ', 'Recommended input')}: ${_profile.recommendedInput}',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('sensor-config-save'),
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    context.l10n.text('บันทึกเซ็นเซอร์', 'Save sensor'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
