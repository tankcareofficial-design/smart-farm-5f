import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../models/output_device.dart';
import '../models/sensor_config.dart';
import '../models/sensor_model.dart';
import '../stores/device_store.dart';
import '../stores/sensor_store.dart';

class OutputDeviceDialog extends StatefulWidget {
  const OutputDeviceDialog({
    super.key,
    required this.store,
    required this.sensorStore,
    this.existingDevice,
  });

  final DeviceStore store;
  final SensorStore sensorStore;
  final OutputDevice? existingDevice;

  @override
  State<OutputDeviceDialog> createState() => _OutputDeviceDialogState();
}

class _OutputDeviceDialogState extends State<OutputDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _conditionValueController;
  late final TextEditingController _conditionStopValueController;

  late OutputDeviceType _selectedType;
  late OutputControlMode _selectedMode;
  late int _selectedChannel;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _daysMask;
  String? _selectedSensorId;
  late String _conditionMetric;
  late String _conditionOperator;
  late double _conditionValue;
  late double _conditionStopValue;
  int _currentStep = 0;
  bool _localizedDefaultNameApplied = false;
  bool _isSaving = false;

  bool get isEditing => widget.existingDevice != null;
  List<SensorConfig> get _availableSensors => widget.sensorStore.configs
      .where((sensor) => sensor.enabled)
      .toList(growable: false);

  SensorConfig? get _selectedSensor {
    for (final sensor in _availableSensors) {
      if (sensor.id == _selectedSensorId) {
        return sensor;
      }
    }
    return null;
  }

  bool get _hasConfigurationStep => _selectedMode != OutputControlMode.manual;
  int get _stepCount => _hasConfigurationStep ? 4 : 3;
  bool get _isLastStep => _currentStep == _stepCount - 1;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingDevice;
    _selectedType = existing?.type ?? OutputDeviceType.pump;
    _nameController = TextEditingController(
      text: existing?.name ?? _fallbackDefaultNameForType(_selectedType),
    );
    _selectedMode = existing?.mode ?? OutputControlMode.manual;
    _selectedChannel = existing?.channel ?? _findFirstAvailableChannel();
    _startTime = TimeOfDay(
      hour: existing?.schedule.hour ?? 6,
      minute: existing?.schedule.minute ?? 0,
    );
    _endTime = TimeOfDay(
      hour: existing?.schedule.endHour ?? 6,
      minute: existing?.schedule.endMinute ?? 15,
    );
    _daysMask = existing?.schedule.daysMask ?? 0x7F;
    _selectedSensorId = existing?.condition.sensorId.isNotEmpty == true
        ? existing!.condition.sensorId
        : null;
    _conditionMetric = existing?.condition.metric ?? '';
    _conditionOperator = existing?.condition.operator ?? '<';
    _conditionValue = existing?.condition.value ?? 40;
    _conditionStopValue = existing?.condition.stopValue ?? 55;
    _conditionValueController = TextEditingController(
      text: _conditionValue.toStringAsFixed(0),
    );
    _conditionStopValueController = TextEditingController(
      text: _conditionStopValue.toStringAsFixed(0),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedDefaultNameApplied || isEditing) {
      return;
    }
    final fallbackName = _fallbackDefaultNameForType(_selectedType);
    if (_nameController.text == fallbackName) {
      _nameController.text = _defaultNameForType(_selectedType);
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    }
    _localizedDefaultNameApplied = true;
  }

  String _fallbackDefaultNameForType(OutputDeviceType type) {
    return switch (type) {
      OutputDeviceType.pump => 'ปั๊มน้ำ',
      OutputDeviceType.valve => 'วาล์วน้ำ',
      OutputDeviceType.fan => 'พัดลม',
      OutputDeviceType.light => 'ไฟส่องสว่าง',
      OutputDeviceType.fogger => 'เครื่องพ่นหมอก',
      OutputDeviceType.custom => 'อุปกรณ์กำหนดเอง',
    };
  }

  int _findFirstAvailableChannel() {
    for (var channel = 1; channel <= 8; channel++) {
      if (!widget.store.isChannelUsed(channel)) {
        return channel;
      }
    }
    return 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _conditionValueController.dispose();
    _conditionStopValueController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1 && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_currentStep == 2 &&
        _selectedMode == OutputControlMode.automatic &&
        _availableSensors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มเซ็นเซอร์ก่อนตั้งกฎ')),
      );
      return;
    }
    if (_currentStep < _stepCount - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _selectMode(OutputControlMode mode) {
    setState(() {
      _selectedMode = mode;
      if (_currentStep >= _stepCount) {
        _currentStep = _stepCount - 1;
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 30) {
      setState(() => _currentStep = 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.validate();
      });
      return;
    }
    if (_selectedMode == OutputControlMode.schedule &&
        _startTime.hour == _endTime.hour &&
        _startTime.minute == _endTime.minute) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.text(
              'เวลาเริ่มและเวลาสิ้นสุดต้องไม่เท่ากัน',
              'Start and end times must be different',
            ),
          ),
        ),
      );
      return;
    }
    if (_selectedMode == OutputControlMode.schedule && _daysMask == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.text(
              'กรุณาเลือกอย่างน้อย 1 วัน',
              'Select at least one day',
            ),
          ),
        ),
      );
      return;
    }
    final parsedValue = double.tryParse(_conditionValueController.text.trim());
    final parsedStopValue = double.tryParse(
      _conditionStopValueController.text.trim(),
    );
    if (_selectedMode == OutputControlMode.automatic &&
        (_selectedSensor == null ||
            parsedValue == null ||
            parsedStopValue == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.text(
              'กรุณาเลือกเซ็นเซอร์และกรอกค่าเริ่ม/หยุด',
              'Select a sensor and enter start/stop values',
            ),
          ),
        ),
      );
      return;
    }
    if (parsedValue != null) {
      _conditionValue = parsedValue;
    }
    if (parsedStopValue != null) {
      _conditionStopValue = parsedStopValue;
    }
    final selectedSensor = _selectedSensor;
    if (_selectedMode == OutputControlMode.automatic &&
        selectedSensor != null) {
      _conditionMetric = _metricForType(selectedSensor.type);
    }

    final existing = widget.existingDevice;
    final device = OutputDevice(
      id: existing?.id ?? 'output-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: _selectedType,
      channel: _selectedChannel,
      isOn: existing?.isOn ?? false,
      enabled: existing?.enabled ?? true,
      mode: _selectedMode,
      requestedOn: existing?.requestedOn ?? false,
      runtimeState: existing?.runtimeState ?? 'off',
      waitingReason: existing?.waitingReason ?? '',
      remainingSeconds: existing?.remainingSeconds ?? 0,
      schedule: DeviceScheduleConfig(
        enabled: _selectedMode == OutputControlMode.schedule,
        hour: _startTime.hour,
        minute: _startTime.minute,
        endHour: _endTime.hour,
        endMinute: _endTime.minute,
        daysMask: _daysMask,
      ),
      condition: DeviceConditionConfig(
        enabled: _selectedMode == OutputControlMode.automatic,
        sensorId: selectedSensor?.id ?? '',
        metric: _conditionMetric,
        operator: _conditionOperator,
        value: _conditionValue,
        stopValue: _conditionStopValue,
      ),
    );

    setState(() => _isSaving = true);
    try {
      final saved = isEditing
          ? await widget.store.updateOutput(device)
          : await widget.store.addOutput(device);
      if (!mounted) return;
      if (saved) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.store.lastCommandError ??
                  context.l10n.text('บันทึกไม่สำเร็จ กรุณาลองใหม่', 'Save failed. Please retry.'),
            ),
          ),
        );
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(top: 11),
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _stepCount,
                    minHeight: 7,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
              ),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: SingleChildScrollView(
                    key: ValueKey('${_currentStep}_${_selectedMode.name}'),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? context.l10n.text('แก้ไขอุปกรณ์', 'Edit device')
                      : context.l10n.text('เพิ่มอุปกรณ์', 'Add device'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  context.l10n.text(
                    'ขั้นตอน ${_currentStep + 1} จาก $_stepCount',
                    'Step ${_currentStep + 1} of $_stepCount',
                  ),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.text('ปิด', 'Close'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _stepTitle(String title, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildStepTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: _stepTitle(title, subtitle)),
      ],
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: context.l10n.text(
        isStart ? 'เลือกเวลาเปิด' : 'เลือกเวลาปิด',
        isStart ? 'Select start time' : 'Select stop time',
      ),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) {
      return _buildTypeStep();
    }
    if (_currentStep == 1) {
      return _buildInformationStep();
    }
    if (_currentStep == 2) {
      return _buildModeStep();
    }
    return _selectedMode == OutputControlMode.schedule
        ? _buildScheduleStep()
        : _buildConditionStep();
  }

  Widget _buildTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          context.l10n.text('เลือกประเภทอุปกรณ์', 'Select device type'),
          context.l10n.text(
            'เลือกอุปกรณ์ที่ต้องการควบคุม แล้วกดถัดไป',
            'Choose the device to control, then continue',
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: OutputDeviceType.values.map((type) {
                return SizedBox(
                  width: width,
                  child: _SelectionCard(
                    selected: _selectedType == type,
                    icon: _iconForType(type),
                    title: _typeName(type),
                    onTap: () => _selectType(type),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInformationStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle(
            context.l10n.text('ข้อมูลอุปกรณ์', 'Device information'),
            context.l10n.text(
              'ตั้งชื่อและเลือกช่องรีเลย์ที่ต่อกับอุปกรณ์',
              'Name the device and select its relay channel',
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.l10n.text('ชื่ออุปกรณ์', 'Device name'),
              border: const OutlineInputBorder(),
              prefixIcon: Icon(_iconForType(_selectedType)),
            ),
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) {
                return context.l10n.text(
                  'กรุณากรอกชื่ออุปกรณ์',
                  'Enter a device name',
                );
              }
              if (name.length > 30) {
                return context.l10n.text(
                  'ชื่ออุปกรณ์ต้องไม่เกิน 30 ตัวอักษร',
                  'The name must be 30 characters or fewer',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.text('ช่องรีเลย์', 'Relay channel'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final channel = index + 1;
              final used = widget.store.isChannelUsed(
                channel,
                excludingDeviceId: widget.existingDevice?.id,
              );
              return _ChannelCard(
                channel: channel,
                used: used,
                selected: _selectedChannel == channel,
                onTap: used
                    ? null
                    : () => setState(() => _selectedChannel = channel),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          context.l10n.text('เลือกรูปแบบการทำงาน', 'Choose control mode'),
          context.l10n.text(
            'เลือกโหมดก่อน แล้วกดถัดไปเพื่อตั้งค่ารายละเอียด',
            'Choose a mode, then continue to configure it',
          ),
        ),
        const SizedBox(height: 16),
        _ModeCard(
          selected: _selectedMode == OutputControlMode.manual,
          icon: Icons.touch_app_rounded,
          title: context.l10n.text('ควบคุมเอง', 'Manual control'),
          subtitle: context.l10n.text(
            'เปิดหรือปิดจากหน้าอุปกรณ์',
            'Turn it on or off from the device page',
          ),
          onTap: () => _selectMode(OutputControlMode.manual),
        ),
        const SizedBox(height: 10),
        _ModeCard(
          selected: _selectedMode == OutputControlMode.schedule,
          icon: Icons.alarm_rounded,
          title: context.l10n.text('ตั้งเวลา', 'Schedule'),
          subtitle: context.l10n.text(
            'หน้าถัดไปเลือกวัน เวลาเปิด และเวลาปิด',
            'Next, choose days, start time, and stop time',
          ),
          onTap: () => _selectMode(OutputControlMode.schedule),
        ),
        const SizedBox(height: 10),
        _ModeCard(
          selected: _selectedMode == OutputControlMode.automatic,
          icon: Icons.sensors_rounded,
          title: context.l10n.text('ตามเซ็นเซอร์', 'Sensor condition'),
          subtitle: context.l10n.text(
            'หน้าถัดไปเลือกเซ็นเซอร์และกฎการทำงาน',
            'Next, choose a sensor and its rule',
          ),
          onTap: _availableSensors.isEmpty
              ? null
              : () => _selectMode(OutputControlMode.automatic),
        ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          context.l10n.text('ตั้งเวลาแบบไทม์เมอร์', 'Timer schedule'),
          context.l10n.text(
            'กำหนดวันทำงาน เวลาเริ่ม และเวลาหยุด',
            'Set active days, start time, and stop time',
          ),
        ),
        const SizedBox(height: 18),
        _TimeTile(
          icon: Icons.play_arrow_rounded,
          label: context.l10n.text('เวลาเปิด', 'Start time'),
          time: _startTime,
          onTap: () => _pickTime(true),
        ),
        const SizedBox(height: 10),
        _TimeTile(
          icon: Icons.stop_rounded,
          label: context.l10n.text('เวลาปิด', 'Stop time'),
          time: _endTime,
          onTap: () => _pickTime(false),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.text('ทำงานวันไหนบ้าง', 'Active days'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final bit = 1 << index;
            return FilterChip(
              selected: (_daysMask & bit) != 0,
              label: Text(_dayLabel(index)),
              onSelected: (selected) {
                setState(() {
                  _daysMask = selected ? _daysMask | bit : _daysMask & ~bit;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _daysMask = 0x7F),
              child: Text(context.l10n.text('ทุกวัน', 'Every day')),
            ),
            TextButton(
              onPressed: () => setState(() => _daysMask = 0x1F),
              child: Text(context.l10n.text('จันทร์–ศุกร์', 'Weekdays')),
            ),
            TextButton(
              onPressed: () => setState(() => _daysMask = 0x60),
              child: Text(context.l10n.text('เสาร์–อาทิตย์', 'Weekend')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionStep() {
    final colors = Theme.of(context).colorScheme;
    final sensor = _selectedSensor;
    final unit = sensor == null ? '%' : _unitForType(sensor.type);
    final situation = sensor == null
        ? 'เลือกเซ็นเซอร์ก่อน'
        : _situationForType(sensor.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(
          icon: Icons.sensors_rounded,
          title: context.l10n.text(
            'ตั้งกฎจากเซ็นเซอร์',
            'Configure sensor rule',
          ),
          subtitle: context.l10n.text(
            'เลือกเฉพาะเซ็นเซอร์ที่เพิ่มไว้จริง แล้วกำหนดค่าเริ่มและค่าหยุด',
            'Choose an installed sensor, then set start and stop values',
          ),
        ),
        const SizedBox(height: 18),
        if (_availableSensors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              context.l10n.text(
                'ยังไม่มีเซ็นเซอร์ในระบบ กรุณาเพิ่มเซ็นเซอร์ก่อน',
                'No sensors are configured. Add a sensor first.',
              ),
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        else ...[
          Text(
            context.l10n.text(
              'เลือกเซ็นเซอร์ที่ติดตั้งจริง',
              'Choose an installed sensor',
            ),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final item in _availableSensors) ...[
            _SensorChoiceCard(
              selected: item.id == _selectedSensorId,
              name: item.name,
              typeLabel: _sensorTypeLabel(item.type),
              icon: _sensorIcon(item.type),
              onTap: () {
                setState(() {
                  _selectedSensorId = item.id;
                  _conditionMetric = _metricForType(item.type);
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    situation,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ThresholdEditor(
            title: context.l10n.text(
              'เริ่มเปิดอุปกรณ์เมื่อ',
              'Start device when',
            ),
            description: context.l10n.text('ค่าต่ำกว่า', 'Value is below'),
            controller: _conditionValueController,
            unit: unit,
          ),
          const SizedBox(height: 14),
          _ThresholdEditor(
            title: context.l10n.text('หยุดอุปกรณ์เมื่อ', 'Stop device when'),
            description: context.l10n.text('ค่าเพิ่มถึง', 'Value reaches'),
            controller: _conditionStopValueController,
            unit: unit,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.text(
              'การแยกค่าเริ่มและค่าหยุดช่วยป้องกันรีเลย์เปิด–ปิดถี่',
              'Separate start and stop values prevent rapid relay switching.',
            ),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  String _sensorTypeLabel(SensorType type) => switch (type) {
    SensorType.temperature => 'อุณหภูมิ',
    SensorType.humidity => 'ความชื้นอากาศ',
    SensorType.soilMoisture => 'ความชื้นดิน',
    SensorType.waterLevel => 'ระดับน้ำ',
    SensorType.battery => 'แบตเตอรี่',
    SensorType.solar => 'โซลาร์เซลล์',
  };

  IconData _sensorIcon(SensorType type) => switch (type) {
    SensorType.temperature => Icons.thermostat_rounded,
    SensorType.humidity => Icons.water_drop_rounded,
    SensorType.soilMoisture => Icons.grass_rounded,
    SensorType.waterLevel => Icons.waves_rounded,
    SensorType.battery => Icons.battery_charging_full_rounded,
    SensorType.solar => Icons.solar_power_rounded,
  };

  String _metricForType(SensorType type) => switch (type) {
    SensorType.temperature => 'temperature',
    SensorType.humidity => 'humidity',
    SensorType.soilMoisture => 'soil_moisture',
    SensorType.waterLevel => 'water_level',
    SensorType.battery => 'battery',
    SensorType.solar => 'solar',
  };

  String _unitForType(SensorType type) =>
      type == SensorType.temperature ? '°C' : '%';

  String _situationForType(SensorType type) => switch (type) {
    SensorType.temperature => 'ให้อุปกรณ์ทำงานเมื่ออากาศร้อนเกินไป',
    SensorType.humidity => 'ให้อุปกรณ์ทำงานเมื่ออากาศแห้งเกินไป',
    SensorType.soilMoisture => 'ให้อุปกรณ์ทำงานเมื่อดินแห้งเกินไป',
    SensorType.waterLevel => 'ให้อุปกรณ์ทำงานเมื่อระดับน้ำต่ำเกินไป',
    SensorType.battery => 'ให้อุปกรณ์ทำงานเมื่อแบตเตอรี่ต่ำเกินไป',
    SensorType.solar => 'ให้อุปกรณ์ทำงานเมื่อพลังงานแสงอาทิตย์ต่ำเกินไป',
  };

  Widget _buildBottomActions() {
    final colors = Theme.of(context).colorScheme;
    final manualFinish =
        _currentStep == 2 && _selectedMode == OutputControlMode.manual;
    final shouldSave = _isLastStep || manualFinish;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(context.l10n.text('ย้อนกลับ', 'Back')),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : (shouldSave ? _save : _nextStep),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      shouldSave ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    ),
              label: Text(
                shouldSave
                    ? (isEditing
                          ? context.l10n.text('บันทึกการแก้ไข', 'Save changes')
                          : context.l10n.text('เพิ่มอุปกรณ์', 'Add device'))
                    : context.l10n.text('ถัดไป', 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _defaultNameForType(OutputDeviceType type) => _typeName(type);

  void _selectType(OutputDeviceType type) {
    final previousDefault = _defaultNameForType(_selectedType);
    final currentName = _nameController.text.trim();
    setState(() {
      _selectedType = type;
      if (!isEditing && (currentName.isEmpty || currentName == previousDefault || currentName == 'วาล์วน้ำ')) {
        _nameController.text = _defaultNameForType(type);
        _nameController.selection = TextSelection.collapsed(offset: _nameController.text.length);
      }
    });
  }

  String _typeName(OutputDeviceType type) {
    switch (type) {
      case OutputDeviceType.pump:
        return context.l10n.text('ปั๊มน้ำ', 'Water pump');
      case OutputDeviceType.valve:
        return context.l10n.text('วาล์วน้ำ', 'Water valve');
      case OutputDeviceType.fan:
        return context.l10n.text('พัดลม', 'Fan');
      case OutputDeviceType.light:
        return context.l10n.text('ไฟส่องสว่าง', 'Light');
      case OutputDeviceType.fogger:
        return context.l10n.text('เครื่องพ่นหมอก', 'Fogger');
      case OutputDeviceType.custom:
        return context.l10n.text('อุปกรณ์กำหนดเอง', 'Custom device');
    }
  }

  IconData _iconForType(OutputDeviceType type) {
    switch (type) {
      case OutputDeviceType.pump:
        return Icons.water_rounded;
      case OutputDeviceType.valve:
        return Icons.water_drop_rounded;
      case OutputDeviceType.fan:
        return Icons.air_rounded;
      case OutputDeviceType.light:
        return Icons.lightbulb_rounded;
      case OutputDeviceType.fogger:
        return Icons.cloud_rounded;
      case OutputDeviceType.custom:
        return Icons.electrical_services_rounded;
    }
  }

  String _dayLabel(int index) {
    const th = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return context.l10n.text(th[index], en[index]);
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: selected ? 2 : 1,
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 19,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.used,
    required this.selected,
    required this.onTap,
  });
  final int channel;
  final bool used;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                width: selected ? 2 : 1,
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$channel',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: used
                        ? colors.onSurface.withValues(alpha: 0.30)
                        : null,
                  ),
                ),
                Text(
                  used
                      ? context.l10n.text('ใช้งานแล้ว', 'Used')
                      : context.l10n.text('ว่าง', 'Available'),
                  style: TextStyle(
                    fontSize: 9,
                    color: used
                        ? colors.onSurface.withValues(alpha: 0.30)
                        : colors.onSurfaceVariant,
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: selected ? 2 : 1,
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  size: 30,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.time,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: colors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        trailing: Text(
          time.format(context),
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}

class _SensorChoiceCard extends StatelessWidget {
  const _SensorChoiceCard({
    required this.selected,
    required this.name,
    required this.typeLabel,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String name;
  final String typeLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: selected ? 2 : 1,
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThresholdEditor extends StatelessWidget {
  const _ThresholdEditor({
    required this.title,
    required this.description,
    required this.controller,
    required this.unit,
  });

  final String title;
  final String description;
  final TextEditingController controller;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            decoration: InputDecoration(suffixText: unit, filled: true),
          ),
        ],
      ),
    );
  }
}
