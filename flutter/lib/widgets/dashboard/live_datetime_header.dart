import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/sf_colors.dart';
import '../../core/theme/sf_radius.dart';
import '../../core/theme/sf_spacing.dart';
import '../../core/theme/sf_text_styles.dart';

class LiveDateTimeHeader extends StatefulWidget {
  const LiveDateTimeHeader({super.key, this.showSeconds = true});

  final bool showSeconds;

  @override
  State<LiveDateTimeHeader> createState() => _LiveDateTimeHeaderState();
}

class _LiveDateTimeHeaderState extends State<LiveDateTimeHeader> {
  late DateTime _now;
  Timer? _clockTimer;

  static const List<String> _thaiWeekdays = <String>[
    '',
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ];

  static const List<String> _thaiMonths = <String>[
    '',
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  @override
  void initState() {
    super.initState();

    _now = DateTime.now();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String greeting = _getGreeting(context, _now.hour);

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: SFRadius.medium,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.eco_rounded, color: SFColors.primary);
              },
            ),
          ),
        ),
        SFSpacing.horizontalSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Flexible(
                    child: Text(
                      'Smart Farm+',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SFTextStyles.title,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    greeting,
                    style: SFTextStyles.caption.copyWith(
                      color: SFColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(context, _now),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SFTextStyles.caption,
              ),
              const SizedBox(height: 1),
              Text(
                _formatTime(context, _now),
                style: SFTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime value) {
    if (context.l10n.isThai) {
      final String weekday = _thaiWeekdays[value.weekday];
      final String month = _thaiMonths[value.month];
      final int buddhistYear = value.year + 543;
      return '$weekday ${value.day} $month $buddhistYear';
    }

    const englishWeekdays = <String>[
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const englishMonths = <String>[
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${englishWeekdays[value.weekday]}, ${englishMonths[value.month]} ${value.day}, ${value.year}';
  }

  String _formatTime(BuildContext context, DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    final String second = value.second.toString().padLeft(2, '0');

    if (widget.showSeconds) {
      return context.l10n.isThai
          ? '$hour:$minute:$second น.'
          : '$hour:$minute:$second';
    }

    return context.l10n.isThai ? '$hour:$minute น.' : '$hour:$minute';
  }

  String _getGreeting(BuildContext context, int hour) {
    if (hour >= 5 && hour < 12) {
      return context.l10n.text('สวัสดีตอนเช้า', 'Good morning');
    }

    if (hour >= 12 && hour < 17) {
      return context.l10n.text('สวัสดีตอนบ่าย', 'Good afternoon');
    }

    if (hour >= 17 && hour < 21) {
      return context.l10n.text('สวัสดีตอนเย็น', 'Good evening');
    }

    return context.l10n.text('สวัสดีตอนกลางคืน', 'Good night');
  }
}
