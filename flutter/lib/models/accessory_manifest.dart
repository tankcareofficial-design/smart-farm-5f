enum AccessoryStatus {
  connected,
  waiting,
  notInstalled,
  unavailable,
  error,
  detecting,
  waitingForData,
  stale,
  disabled,
}

typedef AccessoryConnectionState = AccessoryStatus;

class AccessoryCapability {
  const AccessoryCapability({
    required this.key,
    required this.label,
    required this.unit,
  });

  final String key;
  final String label;
  final String unit;

  factory AccessoryCapability.fromJson(Map<dynamic, dynamic> json) {
    return AccessoryCapability(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
    );
  }
}

class AccessoryManifest {
  const AccessoryManifest({
    this.deviceId = '',
    this.deviceType = 'unknown',
    required this.portId,
    required this.role,
    required this.displayName,
    required this.status,
    required this.capabilities,
    this.connectionType = 'unknown',
    this.lastSeenMs,
    this.lastError,
  });

  final String deviceId;
  final String deviceType;
  final String portId;
  final String role;
  final String displayName;
  final AccessoryConnectionState status;
  final List<AccessoryCapability> capabilities;
  final String connectionType;
  final int? lastSeenMs;
  final String? lastError;

  bool get connected => status == AccessoryConnectionState.connected;
  bool get hasUsableData =>
      connected || status == AccessoryConnectionState.stale;
  bool get installed => !<AccessoryConnectionState>{
    AccessoryConnectionState.notInstalled,
    AccessoryConnectionState.unavailable,
  }.contains(status);

  factory AccessoryManifest.fromJson(Map<dynamic, dynamic> json) {
    final rawCapabilities = json['capabilities'];
    final portId = json['portId']?.toString() ?? '';
    final role = json['role']?.toString() ?? '';
    return AccessoryManifest(
      deviceId:
          json['deviceId']?.toString() ?? (portId.isEmpty ? role : portId),
      deviceType: json['deviceType']?.toString() ?? 'unknown',
      portId: portId,
      role: role,
      displayName: json['displayName']?.toString() ?? '',
      status: _statusFrom(json['status']?.toString()),
      capabilities: rawCapabilities is List
          ? rawCapabilities
                .whereType<Map>()
                .map(AccessoryCapability.fromJson)
                .toList(growable: false)
          : const <AccessoryCapability>[],
      connectionType: json['connectionType']?.toString() ?? 'unknown',
      lastSeenMs: _toInt(json['lastSeenMs']),
      lastError: json['lastError']?.toString(),
    );
  }

  static AccessoryConnectionState _statusFrom(String? value) {
    switch (value) {
      case 'connected':
        return AccessoryConnectionState.connected;
      case 'detecting':
        return AccessoryConnectionState.detecting;
      case 'waiting':
      case 'waiting_for_data':
        return AccessoryConnectionState.waitingForData;
      case 'stale':
        return AccessoryConnectionState.stale;
      case 'disabled':
        return AccessoryConnectionState.disabled;
      case 'unavailable':
        return AccessoryConnectionState.unavailable;
      case 'error':
        return AccessoryConnectionState.error;
      case 'not_installed':
      default:
        return AccessoryConnectionState.notInstalled;
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
