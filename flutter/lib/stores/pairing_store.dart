import 'package:flutter/foundation.dart';

import '../models/controller_candidate.dart';
import '../models/wifi_network.dart';
import '../services/esp32_http_service.dart';

enum PairingStage {
  searching,
  selectController,
  selectWifi,
  enterPassword,
  connecting,
  success,
}

class PairingStore extends ChangeNotifier {
  PairingStore({Esp32HttpService? httpService})
    : _http = httpService ?? Esp32HttpService();

  final Esp32HttpService _http;
  PairingStage _stage = PairingStage.searching;
  List<ControllerCandidate> _controllers = const <ControllerCandidate>[];
  List<WifiNetwork> _wifiNetworks = const <WifiNetwork>[];
  ControllerCandidate? _selectedController;
  WifiNetwork? _selectedWifi;
  String _password = '';
  double _progress = 0;
  String? _error;
  bool _busy = false;
  String? _stationIp;
  String? _stationSsid;
  String? _accessPointSsid;
  String _accessPointIp = '192.168.4.1';

  PairingStage get stage => _stage;
  List<ControllerCandidate> get controllers => _controllers;
  List<WifiNetwork> get wifiNetworks => _wifiNetworks;
  ControllerCandidate? get selectedController => _selectedController;
  String? get selectedWifi => _selectedWifi?.ssid;
  double get progress => _progress;
  String? get error => _error;
  bool get busy => _busy;
  String? get stationIp => _stationIp;
  String? get stationSsid => _stationSsid;

  /// Called after the user manually connects the phone to the SmartFarm AP.
  /// Verifies 192.168.4.1, identifies the box and asks the ESP32 to scan Wi-Fi.
  Future<void> startSearch() async {
    if (_busy) return;
    _busy = true;
    _stage = PairingStage.searching;
    _error = null;
    notifyListeners();

    try {
      final device = await _http.getDevice();
      final controller = ControllerCandidate(
        id: device['deviceId']?.toString() ?? 'ESP32',
        name: device['ssid']?.toString() ?? 'SmartFarm Controller',
        signalStrength: 0,
        firmwareVersion: device['firmwareVersion']?.toString() ?? '-',
        accessPointSsid: device['ssid']?.toString(),
        accessPointIp: device['accessPointIp']?.toString() ?? '192.168.4.1',
      );
      _accessPointSsid = controller.accessPointSsid;
      _accessPointIp = controller.accessPointIp ?? '192.168.4.1';
      _controllers = <ControllerCandidate>[controller];
      _selectedController = controller;

      final networks = await _http.scanWifi();
      networks.sort((a, b) => b.rssi.compareTo(a.rssi));
      _wifiNetworks = networks;
      _stage = PairingStage.selectWifi;
      if (networks.isEmpty) {
        _error = 'กล่องควบคุมไม่พบเครือข่าย Wi-Fi กรุณากดสแกนใหม่';
      }
    } catch (error) {
      _controllers = const <ControllerCandidate>[];
      _wifiNetworks = const <WifiNetwork>[];
      _error =
          'ยังติดต่อ Controller ไม่ได้ กรุณาเชื่อม Wi-Fi SmartFarm-xxxxxx ด้วยรหัสบนกล่อง แล้วกดเชื่อมต่ออีกครั้ง: $error';
      _stage = PairingStage.selectController;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> selectController(ControllerCandidate controller) async {
    _selectedController = controller;
    await startSearch();
  }

  Future<void> rescanWifi() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final networks = await _http.scanWifi();
      networks.sort((a, b) => b.rssi.compareTo(a.rssi));
      _wifiNetworks = networks;
      if (networks.isEmpty) {
        _error = 'ไม่พบเครือข่าย Wi-Fi';
      }
    } catch (error) {
      _error = 'กล่องควบคุมค้นหา Wi-Fi ไม่สำเร็จ: $error';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void selectWifi(String wifiName) {
    _selectedWifi = _wifiNetworks.firstWhere(
      (network) => network.ssid == wifiName,
    );
    _stage = PairingStage.enterPassword;
    _error = null;
    notifyListeners();
  }

  void updatePassword(String value) => _password = value;

  Future<void> connect() async {
    if (_selectedController == null || _selectedWifi == null || _busy) return;
    _busy = true;
    _stage = PairingStage.connecting;
    _progress = .15;
    _error = null;
    notifyListeners();

    try {
      _progress = .40;
      notifyListeners();
      final response = await _http.connectWifi(
        ssid: _selectedWifi!.ssid,
        password: _password,
      );
      _progress = .85;
      notifyListeners();
      if (response['connected'] != true) {
        throw Esp32HttpException(
          response['message']?.toString() ??
              'กล่องควบคุมเชื่อมต่อ Wi-Fi ไม่สำเร็จ',
        );
      }
      final String ip = (response['stationIp'] ?? response['ip'] ?? '')
          .toString()
          .trim();
      if (ip.isEmpty || ip == '0.0.0.0') {
        throw const Esp32HttpException(
          'กล่องควบคุมเชื่อม Wi-Fi แล้ว แต่ยังไม่พร้อมใช้งาน',
        );
      }
      _stationIp = ip;
      _stationSsid = (response['ssid'] ?? _selectedWifi!.ssid).toString();
      _progress = 1;
      _stage = PairingStage.success;
    } catch (error) {
      _error = 'ตั้งค่า Wi-Fi ไม่สำเร็จ: $error';
      _stage = PairingStage.enterPassword;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void goBack() {
    switch (_stage) {
      case PairingStage.selectWifi:
      case PairingStage.selectController:
        _stage = PairingStage.searching;
        break;
      case PairingStage.enterPassword:
        _stage = PairingStage.selectWifi;
        break;
      case PairingStage.success:
        _stage = PairingStage.enterPassword;
        break;
      case PairingStage.searching:
      case PairingStage.connecting:
        return;
    }
    notifyListeners();
  }

  PairingResult? buildResult() {
    final controller = _selectedController;
    final wifi = _selectedWifi;
    if (controller == null || wifi == null || _stationIp == null) return null;
    return PairingResult(
      controllerId: controller.id,
      controllerName: controller.name,
      wifiName: _stationSsid ?? wifi.ssid,
      stationIp: _stationIp!,
      firmwareVersion: controller.firmwareVersion,
      accessPointSsid: _accessPointSsid,
      accessPointIp: _accessPointIp,
    );
  }

  @override
  void dispose() {
    _http.close();
    super.dispose();
  }
}
