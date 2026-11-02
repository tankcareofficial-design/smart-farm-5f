import 'package:flutter/material.dart';

enum SensorStatus { online, warning, offline }

enum SensorType {
  temperature,
  humidity,
  soilMoisture,
  waterLevel,
  battery,
  solar,
}

class SensorModel {
  const SensorModel({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.unit,
    required this.icon,
    required this.status,
    required this.updatedAt,
    this.subtitle,
    this.minimum = 0,
    this.maximum = 100,
  });

  final String id;
  final String name;
  final SensorType type;
  final double value;
  final String unit;
  final IconData icon;
  final SensorStatus status;
  final DateTime updatedAt;
  final String? subtitle;
  final double minimum;
  final double maximum;

  double get normalizedValue {
    if (maximum <= minimum) return 0;
    return ((value - minimum) / (maximum - minimum)).clamp(0.0, 1.0);
  }
}
