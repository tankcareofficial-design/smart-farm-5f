class ControllerIdentity {
  const ControllerIdentity({
    required this.controllerId,
    required this.displayName,
    required this.hardwareProfile,
    required this.relayCount,
    required this.firmwareVersion,
    required this.accessorySchemaVersion,
  });

  static const empty = ControllerIdentity(
    controllerId: '',
    displayName: 'กล่องควบคุมฟาร์ม',
    hardwareProfile: 'unknown',
    relayCount: 0,
    firmwareVersion: '',
    accessorySchemaVersion: 1,
  );

  final String controllerId;
  final String displayName;
  final String hardwareProfile;
  final int relayCount;
  final String firmwareVersion;
  final int accessorySchemaVersion;

  bool get isKnown => controllerId.isNotEmpty;

  factory ControllerIdentity.fromJson(Map<dynamic, dynamic> json) {
    return ControllerIdentity(
      controllerId: json['deviceId']?.toString() ?? '',
      displayName: json['displayName']?.toString().trim().isNotEmpty == true
          ? json['displayName'].toString().trim()
          : 'กล่องควบคุมฟาร์ม',
      hardwareProfile: json['hardwareProfile']?.toString() ?? 'unknown',
      relayCount: _toInt(json['relayCount']) ?? 0,
      firmwareVersion: json['firmwareVersion']?.toString() ?? '',
      accessorySchemaVersion: _toInt(json['accessorySchemaVersion']) ?? 1,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
