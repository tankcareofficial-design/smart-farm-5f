import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/sf_colors.dart';
import '../../core/theme/sf_radius.dart';
import '../../core/theme/sf_text_styles.dart';
import '../../core/widgets/sf_card.dart';
import '../../models/farm_event.dart';
import '../../models/farm_state.dart';
import '../../services/farm_health_engine.dart';

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    super.key,
    required this.state,
    this.health,
    this.controllerName = 'กล่องควบคุมฟาร์ม',
  });

  final FarmState state;
  final FarmHealthResult? health;
  final String controllerName;

  @override
  Widget build(BuildContext context) {
    final syncText = state.lastUpdated == null
        ? context.l10n.text('ยังไม่เคยซิงก์', 'Never synced')
        : context.l10n.text(
            'อัปเดตล่าสุด ${_time(state.lastUpdated!)} น.',
            'Last update ${_time(state.lastUpdated!)}',
          );
    final relayText = state.relayCount > 0
        ? context.l10n.text(
            'รีเลย์ ${state.relayCount} ช่อง',
            '${state.relayCount} relays',
          )
        : context.l10n.text('ยังไม่พบรีเลย์', 'No relay profile');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF163D24),
            Color(0xFF23723B),
            Color(0xFF3C9854),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: SFRadius.extraLarge,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SFColors.primary.withValues(alpha: .25),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SFColors.primaryLight.withValues(alpha: .15),
                  borderRadius: SFRadius.medium,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF9BE7A9),
                  size: 26,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.text(
                        'ระบบควบคุมฟาร์ม',
                        'Farm control system',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controllerName.trim().isEmpty
                          ? context.l10n.text(
                              'กล่องควบคุมฟาร์ม',
                              'Farm controller',
                            )
                          : controllerName.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_readinessLabel(context, health?.readiness ?? _fallbackReadiness(state))} • $syncText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(connected: state.connected),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _CompactMetric(
                icon: Icons.power_rounded,
                value: '${state.activeDevices}/${state.totalDevices}',
                label: context.l10n.text('อุปกรณ์ทำงาน', 'Active devices'),
              ),
              _CompactMetric(
                icon: Icons.sensors_rounded,
                value: '${state.enabledSensors}/${state.totalSensors}',
                label: context.l10n.text('เซ็นเซอร์', 'Sensors'),
              ),
              _CompactMetric(
                icon: Icons.electrical_services_rounded,
                value: relayText,
                label: context.l10n.text('ฮาร์ดแวร์', 'Hardware'),
              ),
              _CompactMetric(
                icon: Icons.wifi_rounded,
                value: state.wifiRssi == null
                    ? '-- dBm'
                    : '${state.wifiRssi} dBm',
                label: context.l10n.text('สัญญาณ Wi-Fi', 'Wi-Fi signal'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  FarmReadinessState _fallbackReadiness(FarmState state) {
    if (state.emergencyActive) return FarmReadinessState.emergency;
    if (!state.connected) return FarmReadinessState.disconnected;
    return FarmReadinessState.waitingForData;
  }

  String _readinessLabel(BuildContext context, FarmReadinessState readiness) {
    return switch (readiness) {
      FarmReadinessState.ready => context.l10n.text('พร้อมใช้งาน', 'Ready'),
      FarmReadinessState.partial => context.l10n.text(
        'ใช้งานได้บางส่วน',
        'Partially ready',
      ),
      FarmReadinessState.waitingForData => context.l10n.text(
        'กำลังรอข้อมูลจริง',
        'Waiting for live data',
      ),
      FarmReadinessState.disconnected => context.l10n.text(
        'ยังไม่ได้เชื่อมต่อ',
        'Disconnected',
      ),
      FarmReadinessState.emergency => context.l10n.text(
        'หยุดฉุกเฉิน',
        'Emergency stop',
      ),
      FarmReadinessState.needsAttention => context.l10n.text(
        'ควรตรวจสอบ',
        'Check required',
      ),
    };
  }

  String _time(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class DashboardConnectionBadge extends StatelessWidget {
  const DashboardConnectionBadge({super.key, required this.state});

  final FarmState state;

  @override
  Widget build(BuildContext context) {
    final color = state.emergencyActive
        ? SFColors.danger
        : state.connected
        ? SFColors.success
        : state.requestInProgress
        ? SFColors.warning
        : SFColors.textSecondary;
    final label = state.emergencyActive
        ? context.l10n.text('ฉุกเฉิน', 'Emergency')
        : state.connected
        ? context.l10n.text('ออนไลน์', 'Online')
        : state.requestInProgress
        ? context.l10n.text('กำลังเชื่อมต่อ', 'Connecting')
        : context.l10n.text('ออฟไลน์', 'Offline');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: SFRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 6),
          Text(label, style: SFTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: SFRadius.medium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF9BE7A9), size: 19),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .62),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FarmHealthCard extends StatelessWidget {
  const FarmHealthCard({super.key, required this.result});
  final FarmHealthResult result;

  @override
  Widget build(BuildContext context) {
    final color = !result.isAssessable
        ? SFColors.textSecondary
        : switch (result.level) {
            FarmHealthLevel.excellent => SFColors.success,
            FarmHealthLevel.normal => SFColors.info,
            FarmHealthLevel.warning => SFColors.warning,
            FarmHealthLevel.critical => SFColors.danger,
          };
    final label = switch (result.readiness) {
      FarmReadinessState.ready => context.l10n.text('พร้อมใช้งาน', 'Ready'),
      FarmReadinessState.partial => context.l10n.text(
        'ใช้งานได้บางส่วน',
        'Partially ready',
      ),
      FarmReadinessState.waitingForData => context.l10n.text(
        'กำลังรอข้อมูลจริง',
        'Waiting for live data',
      ),
      FarmReadinessState.disconnected => context.l10n.text(
        'ยังไม่ได้เชื่อมต่อ',
        'Disconnected',
      ),
      FarmReadinessState.emergency => context.l10n.text(
        'หยุดฉุกเฉิน',
        'Emergency stop',
      ),
      FarmReadinessState.needsAttention => context.l10n.text(
        'ควรตรวจสอบ',
        'Check required',
      ),
    };
    return SFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: SFRadius.medium,
                ),
                child: Icon(Icons.health_and_safety_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.text(
                        'ความพร้อมระบบฟาร์ม',
                        'Farm System Readiness',
                      ),
                      style: SFTextStyles.titleLarge,
                    ),
                    Text(
                      label,
                      style: SFTextStyles.bodySecondary.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                result.isAssessable ? '${result.score}' : '--',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                result.isAssessable ? '/100' : '',
                style: SFTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: SFRadius.pill,
            child: LinearProgressIndicator(
              value: result.isAssessable ? result.score / 100 : 0.0,
              minHeight: 9,
              color: color,
              backgroundColor: color.withValues(alpha: .12),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: result.factors
                .map((factor) => _HealthChip(factor: factor))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: SFTextStyles.titleLarge),
            const SizedBox(height: 2),
            Text(subtitle, style: SFTextStyles.bodySecondary),
          ],
        ),
      ),
      TextButton(onPressed: onAction, child: Text(actionLabel)),
    ],
  );
}

class DashboardAlertCard extends StatelessWidget {
  const DashboardAlertCard({
    super.key,
    required this.alerts,
    required this.status,
    required this.events,
  });
  final List<String> alerts;
  final String status;
  final List<FarmEvent> events;
  @override
  Widget build(BuildContext context) {
    final hasAlerts = alerts.isNotEmpty;
    return SFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                hasAlerts
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: hasAlerts ? SFColors.warning : SFColors.success,
              ),
              const SizedBox(width: 10),
              Text(
                context.l10n.text('การแจ้งเตือนระบบ', 'System Alerts'),
                style: SFTextStyles.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAlerts)
            Text(
              context.l10n.text(
                'ไม่มีการแจ้งเตือนที่ต้องดำเนินการ',
                'No alerts require action',
              ),
              style: SFTextStyles.bodySecondary,
            )
          else
            ...alerts
                .take(3)
                .map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: SFColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: SFTextStyles.bodySecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          if (events.isNotEmpty) ...<Widget>[
            const Divider(height: 20),
            ...events
                .take(3)
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          event.severity == FarmEventSeverity.critical
                              ? Icons.error_rounded
                              : event.severity == FarmEventSeverity.warning
                              ? Icons.warning_amber_rounded
                              : Icons.history_rounded,
                          size: 16,
                          color: event.severity == FarmEventSeverity.critical
                              ? SFColors.danger
                              : event.severity == FarmEventSeverity.warning
                              ? SFColors.warning
                              : SFColors.textSecondary,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            event.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SFTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 4),
          Text(
            status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SFTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key, required this.onRelease});
  final VoidCallback onRelease;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: SFColors.danger,
      borderRadius: SFRadius.large,
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'EMERGENCY ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                context.l10n.text(
                  'ระบบอัตโนมัติและรีเลย์ถูกล็อก',
                  'Automation and relays are locked',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onRelease,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(context.l10n.text('ปลดล็อก', 'Release')),
        ),
      ],
    ),
  );
}

class ProjectCreditCard extends StatelessWidget {
  const ProjectCreditCard({super.key});
  @override
  Widget build(BuildContext context) => SFCard(
    child: Column(
      children: <Widget>[
        const Icon(Icons.eco_rounded, color: SFColors.primary, size: 28),
        const SizedBox(height: 6),
        const Text('RTPM • ElecBI-CEC', style: SFTextStyles.title),
        const SizedBox(height: 2),
        Text(
          context.l10n.text(
            'Smart Farm Controller • Powered by ChatGPT',
            'Smart Farm Controller • Powered by ChatGPT',
          ),
          textAlign: TextAlign.center,
          style: SFTextStyles.caption,
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.connected});
  final bool connected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: SFRadius.pill,
      border: Border.all(color: Colors.white.withValues(alpha: .25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.circle,
          size: 9,
          color: connected ? Colors.lightGreenAccent : Colors.orangeAccent,
        ),
        const SizedBox(width: 6),
        Text(
          connected
              ? context.l10n.text('ออนไลน์', 'Online')
              : context.l10n.text('ออฟไลน์', 'Offline'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.factor});
  final FarmHealthFactor factor;
  @override
  Widget build(BuildContext context) {
    final color = factor.status == null
        ? SFColors.textSecondary
        : factor.status!
        ? SFColors.success
        : SFColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: SFRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            factor.status == null
                ? Icons.remove_circle_outline
                : factor.status!
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            factor.label,
            style: SFTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
