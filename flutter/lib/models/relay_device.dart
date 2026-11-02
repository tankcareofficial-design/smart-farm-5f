import 'package:flutter/material.dart';

enum RelayMode { manual, schedule, automatic }

class RelayDevice {
  final int id;
  final String name;
  final String description;
  final IconData icon;
  final bool isOn;
  final RelayMode mode;

  const RelayDevice({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isOn,
    required this.mode,
  });

  RelayDevice copyWith({
    String? name,
    String? description,
    IconData? icon,
    bool? isOn,
    RelayMode? mode,
  }) {
    return RelayDevice(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isOn: isOn ?? this.isOn,
      mode: mode ?? this.mode,
    );
  }
}
