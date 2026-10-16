class AttendanceStatus {
  const AttendanceStatus._(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static const present = AttendanceStatus._('PRESENT', 'Present');
  static const absent = AttendanceStatus._('ABSENT', 'Absent');
  static const halfDay = AttendanceStatus._('HALF_DAY', 'Half day');

  static const values = [present, absent, halfDay];

  static AttendanceStatus fromApi(dynamic value) {
    final apiValue = value?.toString().toUpperCase();

    return values.firstWhere(
      (status) => status.apiValue == apiValue,
      orElse: () => throw FormatException('Unknown attendance status: $value'),
    );
  }

  @override
  String toString() => label;
}

class Attendance {
  const Attendance({
    required this.id,
    required this.attendanceDate,
    required this.status,
    required this.employeeId,
    this.reason,
    this.createdAt,
    this.employeeName = '',
    this.employeeMobile = '',
  });

  final int id;
  final DateTime attendanceDate;
  final AttendanceStatus status;
  final int employeeId;
  final String? reason;
  final DateTime? createdAt;
  final String employeeName;
  final String employeeMobile;

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: _parseInt(json['id']),
      attendanceDate: _parseDate(json['attendanceDate']),
      status: AttendanceStatus.fromApi(json['status']),
      employeeId: _parseInt(json['employeeId']),
      reason: json['reason']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      employeeName: json['employeeName']?.toString() ?? '',
      employeeMobile: json['employeeMobile']?.toString() ?? '',
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
        'The server returned an invalid attendance date.',
      );
    }

    return parsed;
  }
}
