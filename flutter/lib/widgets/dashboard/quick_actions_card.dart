import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/sf_animation.dart';
import '../../core/theme/sf_colors.dart';
import '../../core/theme/sf_radius.dart';
import '../../core/theme/sf_spacing.dart';
import '../../core/theme/sf_text_styles.dart';

class QuickActionsCard extends StatelessWidget {
  final VoidCallback onDevicesPressed;
  final VoidCallback onSensorsPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onEmergencyOffPressed;

  const QuickActionsCard({
    super.key,
    required this.onDevicesPressed,
    required this.onSensorsPressed,
    required this.onSettingsPressed,
    required this.onEmergencyOffPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.text('ทางลัด', 'Quick Actions'),
          style: SFTextStyles.titleLarge,
        ),
        const SizedBox(height: 3),
        Text(
          context.l10n.text(
            'เข้าถึงคำสั่งที่ใช้งานบ่อยได้ทันที',
            'Access frequently used controls instantly',
          ),
          style: SFTextStyles.bodySecondary,
        ),
        SFSpacing.verticalSm,
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = (constraints.maxWidth - SFSpacing.sm) / 2;

            return Wrap(
              spacing: SFSpacing.sm,
              runSpacing: SFSpacing.sm,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _QuickActionButton(
                    title: context.l10n.text('อุปกรณ์', 'Devices'),
                    subtitle: context.l10n.text(
                      'เพิ่มและจัดการ',
                      'Add and manage',
                    ),
                    icon: Icons.add_circle_outline_rounded,
                    color: SFColors.primary,
                    onPressed: onDevicesPressed,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _QuickActionButton(
                    title: context.l10n.text('เซ็นเซอร์', 'Sensors'),
                    subtitle: context.l10n.text(
                      'ตั้งค่าอินพุต',
                      'Configure inputs',
                    ),
                    icon: Icons.sensors_rounded,
                    color: SFColors.info,
                    onPressed: onSensorsPressed,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _QuickActionButton(
                    title: context.l10n.text('ตั้งค่า', 'Settings'),
                    subtitle: context.l10n.text(
                      'ระบบและการเชื่อมต่อ',
                      'System and connection',
                    ),
                    icon: Icons.settings_rounded,
                    color: SFColors.schedule,
                    onPressed: onSettingsPressed,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _QuickActionButton(
                    title: context.l10n.text('ปิดฉุกเฉิน', 'Emergency Stop'),
                    subtitle: context.l10n.text(
                      'ปิดทุกอุปกรณ์',
                      'Turn off all devices',
                    ),
                    icon: Icons.power_settings_new_rounded,
                    color: SFColors.danger,
                    onPressed: onEmergencyOffPressed,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: SFAnimation.fast,
      curve: SFAnimation.standardCurve,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: SFRadius.large,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (value) {
            setState(() {
              _pressed = value;
            });
          },
          borderRadius: SFRadius.large,
          child: Container(
            padding: const EdgeInsets.all(SFSpacing.md),
            decoration: BoxDecoration(
              borderRadius: SFRadius.large,
              border: Border.all(color: widget.color.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.11),
                    borderRadius: SFRadius.medium,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 25),
                ),
                SFSpacing.horizontalSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SFTextStyles.title.copyWith(color: widget.color),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SFTextStyles.caption,
                      ),
                    ],
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
