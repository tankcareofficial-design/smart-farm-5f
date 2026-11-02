enum FarmEventSeverity { info, warning, critical }

class FarmEvent {
  const FarmEvent({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.severity,
  });

  final String id;
  final String message;
  final DateTime timestamp;
  final FarmEventSeverity severity;
}
