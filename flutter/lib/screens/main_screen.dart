import 'dart:async';

import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../controllers/smart_farm_controller.dart';
import '../stores/device_store.dart';
import '../stores/settings_store.dart';
import '../stores/sensor_store.dart';
import 'dashboard_screen.dart';
import 'devices_screen.dart';
import 'sensor_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.settingsStore});

  final SettingsStore settingsStore;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  late final SmartFarmController farmController;
  late final DeviceStore deviceStore;
  final SensorStore sensorStore = SensorStore();

  @override
  void initState() {
    super.initState();
    final settings = widget.settingsStore.settings;
    farmController = SmartFarmController(
      languageCode: settings.languageCode,
      initialBaseUrl: settings.controllerBaseUrl,
    );
    deviceStore = DeviceStore(controller: farmController);
    sensorStore.start();
    if (settings.controllerConfigured && settings.controllerAutoReconnect) {
      unawaited(farmController.connect());
    }
  }

  @override
  void dispose() {
    deviceStore.dispose();
    farmController.dispose();
    sensorStore.dispose();
    super.dispose();
  }

  void _selectPage(int index) {
    setState(() => selectedIndex = index);
    if (index == 1 && farmController.connected) {
      unawaited(farmController.refreshClock());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = <Widget>[
      DashboardScreen(
        store: deviceStore,
        sensorStore: sensorStore,
        controller: farmController,
        onNavigate: _selectPage,
        settingsStore: widget.settingsStore,
      ),
      DevicesScreen(store: deviceStore, sensorStore: sensorStore),
      SensorScreen(store: sensorStore),
      SettingsScreen(store: widget.settingsStore, controller: farmController),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _selectPage,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: l10n.text('หน้าหลัก', 'Dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.power_outlined),
            selectedIcon: const Icon(Icons.power_rounded),
            label: l10n.text('อุปกรณ์', 'Devices'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.sensors_outlined),
            selectedIcon: const Icon(Icons.sensors_rounded),
            label: l10n.text('เซ็นเซอร์', 'Sensors'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.text('ตั้งค่า', 'Settings'),
          ),
        ],
      ),
    );
  }
}
