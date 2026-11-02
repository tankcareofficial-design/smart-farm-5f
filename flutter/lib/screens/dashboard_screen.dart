import 'package:flutter/material.dart';

import '../controllers/smart_farm_controller.dart';
import '../core/localization/app_localizations.dart';
import '../models/farm_state.dart';
import '../services/farm_health_engine.dart';
import '../stores/device_store.dart';
import '../stores/sensor_store.dart';
import '../stores/settings_store.dart';
import '../widgets/dashboard/dashboard_data_widgets.dart';
import '../widgets/dashboard/dashboard_overview_widgets.dart';
import '../widgets/dashboard/live_datetime_header.dart';
import '../widgets/dashboard/quick_actions_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    required this.sensorStore,
    required this.controller,
    required this.onNavigate,
    this.settingsStore,
  });

  final DeviceStore store;
  final SensorStore sensorStore;
  final SmartFarmController controller;
  final ValueChanged<int> onNavigate;
  final SettingsStore? settingsStore;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const FarmHealthEngine _healthEngine = FarmHealthEngine();

  late Listenable _dashboardListenable;
  FarmState _lastGoodState = FarmState.empty;
  Object? _lastBuildError;

  @override
  void initState() {
    super.initState();
    _dashboardListenable = _createListenable();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        oldWidget.sensorStore != widget.sensorStore ||
        oldWidget.controller != widget.controller ||
        oldWidget.settingsStore != widget.settingsStore) {
      _dashboardListenable = _createListenable();
    }
  }

  Listenable _createListenable() => Listenable.merge(<Listenable>[
    widget.store,
    widget.sensorStore,
    widget.controller,
    if (widget.settingsStore != null) widget.settingsStore!,
  ]);

  FarmState _buildSafeState() {
    try {
      final next = FarmState.fromSources(
        controller: widget.controller,
        deviceStore: widget.store,
        sensorStore: widget.sensorStore,
      );
      _lastGoodState = next;
      _lastBuildError = null;
      return next;
    } catch (error, stackTrace) {
      _lastBuildError = error;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'smart_farm.dashboard',
          context: ErrorDescription('while creating the dashboard FarmState'),
        ),
      );
      return _lastGoodState;
    }
  }

  FarmHealthResult _buildSafeHealth(FarmState state) {
    try {
      return _healthEngine.evaluate(state);
    } catch (error, stackTrace) {
      _lastBuildError = error;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'smart_farm.dashboard',
          context: ErrorDescription('while evaluating farm health'),
        ),
      );
      return const FarmHealthResult(
        score: 0,
        level: FarmHealthLevel.critical,
        readiness: FarmReadinessState.needsAttention,
        confidence: 0,
        factors: <FarmHealthFactor>[],
        alerts: <String>['Dashboard data temporarily unavailable'],
        isAssessable: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dashboardListenable,
      builder: (context, _) {
        final farmState = _buildSafeState();
        final health = _buildSafeHealth(farmState);
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: widget.controller.connected
                  ? widget.controller.refreshNow
                  : () async {},
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                children: <Widget>[
                  const LiveDateTimeHeader(),
                  const SizedBox(height: 14),
                  if (_lastBuildError != null) ...<Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.warning_amber_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.l10n.text(
                                  'ข้อมูลบางส่วนโหลดไม่สำเร็จ กำลังแสดงข้อมูลล่าสุดที่ใช้ได้',
                                  'Some data failed to load. Showing the last usable state.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (farmState.emergencyActive) ...<Widget>[
                    EmergencyBanner(onRelease: () => _handleEmergency(context)),
                    const SizedBox(height: 12),
                  ],
                  DashboardHeroCard(
                    state: farmState,
                    health: health,
                    controllerName:
                        widget.settingsStore?.settings.controllerName ??
                        farmState.identity.displayName,
                  ),
                  const SizedBox(height: 14),
                  FarmHealthCard(result: health),
                  const SizedBox(height: 18),
                  QuickActionsCard(
                    onDevicesPressed: () => widget.onNavigate(1),
                    onSensorsPressed: () => widget.onNavigate(2),
                    onSettingsPressed: () => widget.onNavigate(3),
                    onEmergencyOffPressed: () => _handleEmergency(context),
                  ),
                  const SizedBox(height: 18),
                  DashboardSectionHeader(
                    title: context.l10n.text('สภาพแวดล้อม', 'Environment'),
                    subtitle: context.l10n.text(
                      'ข้อมูลจากอุปกรณ์จริง • ไม่มีข้อมูลจำลอง',
                      'Live device data • no simulation',
                    ),
                    actionLabel: context.l10n.text('จัดการ', 'Manage'),
                    onAction: () => widget.onNavigate(2),
                  ),
                  const SizedBox(height: 10),
                  DashboardSensorGrid(
                    store: widget.sensorStore,
                    state: farmState,
                    onAdd: () => widget.onNavigate(2),
                  ),
                  const SizedBox(height: 14),
                  DashboardEnergyCard(state: farmState),
                  const SizedBox(height: 18),
                  DashboardSectionHeader(
                    title: context.l10n.text(
                      'อุปกรณ์ควบคุม',
                      'Control Devices',
                    ),
                    subtitle: context.l10n.text(
                      'รองรับรีเลย์จริง 8 ช่อง',
                      'Eight physical relay channels',
                    ),
                    actionLabel: context.l10n.text('ดูทั้งหมด', 'View all'),
                    onAction: () => widget.onNavigate(1),
                  ),
                  const SizedBox(height: 10),
                  DashboardDevicePreview(
                    store: widget.store,
                    controller: widget.controller,
                  ),
                  const SizedBox(height: 18),
                  DashboardAlertCard(
                    alerts: health.alerts,
                    status: farmState.controllerStatus,
                    events: farmState.events,
                  ),
                  const SizedBox(height: 18),
                  const ProjectCreditCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleEmergency(BuildContext context) async {
    final active = widget.controller.emergencyLatched;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          active
              ? context.l10n.text(
                  'ปลดล็อกระบบฉุกเฉิน?',
                  'Release emergency stop?',
                )
              : context.l10n.text(
                  'ยืนยันหยุดฉุกเฉิน?',
                  'Confirm emergency stop?',
                ),
        ),
        content: Text(
          active
              ? context.l10n.text(
                  'รีเลย์จะไม่เปิดกลับเองหลังปลดล็อก',
                  'Relays will not turn back on automatically.',
                )
              : context.l10n.text(
                  'กล่องควบคุมจะปิดอุปกรณ์ทุกช่องและหยุดระบบอัตโนมัติ',
                  'The control box will turn off all outputs and pause automation.',
                ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.text('ยกเลิก', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.text('ยืนยัน', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final ok = active
        ? await widget.store.releaseEmergencyStop()
        : await widget.store.emergencyStopAllOutputs();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? widget.controller.status
              : widget.store.lastCommandError ??
                    context.l10n.text('คำสั่งไม่สำเร็จ', 'Command failed'),
        ),
      ),
    );
  }
}
