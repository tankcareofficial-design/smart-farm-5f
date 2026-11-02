class ControllerCandidate {
  const ControllerCandidate({
    required this.id,
    required this.name,
    required this.signalStrength,
    required this.firmwareVersion,
    this.accessPointSsid,
    this.accessPointIp,
  });

  final String id;
  final String name;
  final int signalStrength;
  final String firmwareVersion;
  final String? accessPointSsid;
  final String? accessPointIp;
}

class PairingResult {
  const PairingResult({
    required this.controllerId,
    required this.controllerName,
    required this.wifiName,
    required this.stationIp,
    required this.firmwareVersion,
    this.accessPointSsid,
    this.accessPointIp = '192.168.4.1',
  });

  final String controllerId;
  final String controllerName;
  final String wifiName;
  final String stationIp;
  final String firmwareVersion;
  final String? accessPointSsid;
  final String accessPointIp;

  String get stationBaseUrl => 'http://$stationIp';
}
