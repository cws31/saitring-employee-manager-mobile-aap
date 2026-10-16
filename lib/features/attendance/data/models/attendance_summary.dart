class AttendanceSummary {
  const AttendanceSummary({
    required this.attendanceDate,
    required this.present,
    required this.absent,
    required this.halfPresent,
  });

  final DateTime attendanceDate;
  final int present;
  final int absent;
  final int halfPresent;

  int get total => present + absent + halfPresent;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      attendanceDate: _parseDate(json['attendanceDate']),
      present: _parseInt(json['present']),
      absent: _parseInt(json['absent']),
      halfPresent: _parseInt(json['halfPresent']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      throw const FormatException(
        'The server returned an invalid attendance summary date.',
      );
    }

    return parsed;
  }
}
