import 'package:flutter/material.dart';

import '../models/relay_device.dart';

class RelayCard extends StatelessWidget {
  final RelayDevice relay;
  final ValueChanged<bool> onChanged;

  const RelayCard({super.key, required this.relay, required this.onChanged});

  String get modeText {
    switch (relay.mode) {
      case RelayMode.manual:
        return 'Manual';
      case RelayMode.schedule:
        return 'Schedule';
      case RelayMode.automatic:
        return 'Auto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: relay.isOn
              ? activeColor.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: relay.isOn
                  ? activeColor.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              relay.icon,
              color: relay.isOn
                  ? activeColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relay.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${relay.description} • $modeText',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: relay.isOn, onChanged: onChanged),
        ],
      ),
    );
  }
}
