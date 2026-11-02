class SystemHealthState {
  const SystemHealthState({
    required this.score,
    required this.ready,
    required this.status,
    required this.clockReady,
    required this.networkReady,
    required this.sensorDataAvailable,
    required this.heapHealthy,
    required this.freeHeap,
    required this.minimumFreeHeap,
    required this.rssi,
    required this.activeRelayCount,
  });

  final int score;
  final bool ready;
  final String status;
  final bool clockReady;
  final bool networkReady;
  final bool sensorDataAvailable;
  final bool heapHealthy;
  final int freeHeap;
  final int minimumFreeHeap;
  final int rssi;
  final int activeRelayCount;

  factory SystemHealthState.fromJson(Map<String, dynamic> json) {
    return SystemHealthState(
      score: (json['score'] as num?)?.toInt() ?? 0,
      ready: json['ready'] == true,
      status: json['status']?.toString() ?? 'unknown',
      clockReady: json['clockReady'] == true,
      networkReady: json['networkReady'] == true,
      sensorDataAvailable: json['sensorDataAvailable'] == true,
      heapHealthy: json['heapHealthy'] == true,
      freeHeap: (json['freeHeap'] as num?)?.toInt() ?? 0,
      minimumFreeHeap: (json['minimumFreeHeap'] as num?)?.toInt() ?? 0,
      rssi: (json['rssi'] as num?)?.toInt() ?? 0,
      activeRelayCount: (json['activeRelayCount'] as num?)?.toInt() ?? 0,
    );
  }

  static const unavailable = SystemHealthState(
    score: 0,
    ready: false,
    status: 'unavailable',
    clockReady: false,
    networkReady: false,
    sensorDataAvailable: false,
    heapHealthy: false,
    freeHeap: 0,
    minimumFreeHeap: 0,
    rssi: 0,
    activeRelayCount: 0,
  );
}
