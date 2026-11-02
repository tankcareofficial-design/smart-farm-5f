class WifiNetwork {
  const WifiNetwork({
    required this.ssid,
    required this.rssi,
    required this.secure,
  });

  final String ssid;
  final int rssi;
  final bool secure;

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      ssid: json['ssid']?.toString() ?? '',
      rssi: (json['rssi'] as num?)?.toInt() ?? -100,
      secure: json['secure'] == true || json['security'] != 'open',
    );
  }
}
