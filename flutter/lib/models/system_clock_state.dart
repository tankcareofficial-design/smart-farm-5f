class SystemClockState {
  const SystemClockState({
    required this.available,
    required this.valid,
    required this.source,
    this.dateTimeLocal,
    this.lostPower = false,
    this.synchronized = false,
    this.utcOffsetMinutes = 420,
    this.quality = 'unavailable',
    this.readFailures = 0,
  });

  final bool available;
  final bool valid;
  final String source;
  final DateTime? dateTimeLocal;
  final bool lostPower;
  final bool synchronized;
  final int utcOffsetMinutes;
  final String quality;
  final int readFailures;

  factory SystemClockState.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SystemClockState(
        available: false,
        valid: false,
        source: 'none',
      );
    }
    DateTime? parsedDateTime = DateTime.tryParse(
      (json['dateTimeLocal'] ??
                  json['datetimeLocal'] ??
                  json['dateTime'] ??
                  json['datetime'])
              ?.toString() ??
          '',
    );
    if (parsedDateTime == null) {
      final year = (json['year'] as num?)?.toInt();
      final month = (json['month'] as num?)?.toInt();
      final day = (json['day'] as num?)?.toInt();
      final hour = (json['hour'] as num?)?.toInt();
      final minute = (json['minute'] as num?)?.toInt();
      final second = (json['second'] as num?)?.toInt() ?? 0;
      if (year != null &&
          month != null &&
          day != null &&
          hour != null &&
          minute != null) {
        try {
          parsedDateTime = DateTime(year, month, day, hour, minute, second);
        } on ArgumentError {
          parsedDateTime = null;
        }
      }
    }
    return SystemClockState(
      available: json['available'] == true || parsedDateTime != null,
      valid: json['valid'] == true || json['rtcValid'] == true,
      source: json['source']?.toString() ?? 'none',
      dateTimeLocal: parsedDateTime,
      lostPower: json['lostPower'] == true,
      synchronized: json['synchronized'] == true,
      utcOffsetMinutes: (json['utcOffsetMinutes'] as num?)?.toInt() ?? 420,
      quality: json['quality']?.toString() ?? 'unavailable',
      readFailures: (json['readFailures'] as num?)?.toInt() ?? 0,
    );
  }
}
