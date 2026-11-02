import 'package:flutter/material.dart';

import '../controllers/farm_controller.dart';
import '../models/sensor_reading.dart';

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({required this.controller, super.key});
  final FarmController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final readings = controller.state.sensorReadings;
        return Scaffold(
          appBar: AppBar(title: const Text('เซ็นเซอร์')),
          body: readings.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.sensors_off_rounded, size: 54),
                        const SizedBox(height: 12),
                        Text(
                          controller.connected
                              ? 'ยังไม่มีข้อมูลจากเซ็นเซอร์จริง'
                              : 'ยังไม่ได้เชื่อมต่อ Controller',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: readings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final reading = readings[index];
                    return _SensorReadingTile(
                      reading: reading,
                      connected: controller.connected,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _SensorReadingTile extends StatelessWidget {
  const _SensorReadingTile({required this.reading, required this.connected});

  final SensorReading reading;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (reading.state) {
      SensorLiveState.live => 'ข้อมูลจากกล่องควบคุม',
      SensorLiveState.stale => 'ข้อมูลเก่า กรุณาตรวจสอบการเชื่อมต่อ',
      SensorLiveState.waiting => 'กำลังรอข้อมูล',
      SensorLiveState.unavailable => 'ไม่พบเซ็นเซอร์',
      SensorLiveState.error => reading.message ?? 'อ่านค่าไม่สำเร็จ',
    };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          child: Icon(connected ? Icons.sensors_rounded : Icons.sensors_off),
        ),
        title: Text(reading.name),
        subtitle: Text(subtitle),
        trailing: Text(
          reading.value == null
              ? '--'
              : '${reading.value!.toStringAsFixed(1)} ${reading.unit}',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
