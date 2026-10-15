import 'dart:convert';

enum AttendanceStatus {
  present,
  absent,
  halfDay;

  String get apiValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.halfDay:
        return 'HALF_DAY';
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.halfDay:
        return 'Half Day';
    }
  }

  static AttendanceStatus fromApi(dynamic value) {
    switch (value) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'HALF_DAY':
        return AttendanceStatus.halfDay;
      default:
        throw FormatException('Unknown attendance status: $value');
    }
  }
}

class Attendance {
  const Attendance({
    required this.id,
    required this.employeeId,
    required this.attendanceDate,
    required this.status,
    this.reason,
    this.createdAt,
    this.employeeName,
    this.employeeMobile,
  });

  final int id;
  final int employeeId;
  final DateTime attendanceDate;
  final AttendanceStatus status;
  final String? reason;
  final DateTime? createdAt;
  final String? employeeName;
  final String? employeeMobile;

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: _parseId(json['id'], 'id'),
      employeeId: _parseId(json['employeeId'], 'employeeId'),
      attendanceDate: _parseDate(json['attendanceDate']),
      status: AttendanceStatus.fromApi(json['status']),
      reason: _parseOptionalString(json['reason'], 'reason'),
      createdAt: _parseDateTime(json['createdAt']),
      employeeName: _parseOptionalString(json['employeeName'], 'employeeName'),
      employeeMobile: _parseOptionalString(
        json['employeeMobile'],
        'employeeMobile',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'attendanceDate': _formatDate(attendanceDate),
      'status': status.apiValue,
      'reason': reason,
      'createdAt': createdAt?.toIso8601String(),
      'employeeName': employeeName,
      'employeeMobile': employeeMobile,
    };
  }

  Attendance copyWith({
    int? id,
    int? employeeId,
    DateTime? attendanceDate,
    AttendanceStatus? status,
    String? reason,
    DateTime? createdAt,
    String? employeeName,
    String? employeeMobile,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      employeeName: employeeName ?? this.employeeName,
      employeeMobile: employeeMobile ?? this.employeeMobile,
    );
  }

  static int _parseId(dynamic value, String field) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw FormatException('Attendance $field is missing or invalid.');
  }

  static String? _parseOptionalString(dynamic value, String field) {
    if (value == null) return null;
    if (value is String) return value;

    throw FormatException('Attendance $field is invalid.');
  }

  static DateTime _parseDate(dynamic value) {
    if (value is! String) {
      throw const FormatException(
        'Attendance attendanceDate is missing or invalid.',
      );
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw const FormatException('Attendance attendanceDate is invalid.');
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is! String) {
      throw const FormatException('Attendance createdAt is invalid.');
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw const FormatException('Attendance createdAt is invalid.');
    }

    return parsed;
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static List<Attendance> listFromJson(dynamic json) {
    if (json is! List) {
      throw const FormatException(
        'The server did not return an attendance list.',
      );
    }

    return json.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'The server returned an invalid attendance record.',
        );
      }

      return Attendance.fromJson(item);
    }).toList();
  }

  static Attendance fromJsonString(String source) {
    final decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'The server did not return a valid attendance object.',
      );
    }

    return Attendance.fromJson(decoded);
  }
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.attendanceDate,
    required this.present,
    required this.absent,
    required this.halfDay,
  });

  final DateTime attendanceDate;
  final int present;
  final int absent;
  final int halfDay;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      attendanceDate: Attendance._parseDate(json['attendanceDate']),
      present: _parseCount(json['present'], 'present'),
      absent: _parseCount(json['absent'], 'absent'),
      halfDay: _parseCount(json['halfPresent'], 'halfPresent'),
    );
  }

  static int _parseCount(dynamic value, String field) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw FormatException('Attendance summary $field is invalid.');
  }

  static List<AttendanceSummary> listFromJson(dynamic json) {
    if (json is! List) {
      throw const FormatException(
        'The server did not return attendance summaries.',
      );
    }

    return json.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'The server returned an invalid attendance summary.',
        );
      }

      return AttendanceSummary.fromJson(item);
    }).toList();
  }
}
