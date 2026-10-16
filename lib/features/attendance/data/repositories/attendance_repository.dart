import '../../../../core/network/api_client.dart';
import '../models/attendance.dart';
import '../models/attendance_summary.dart';

class AttendanceRepository {
  AttendanceRepository(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/api/attendance';

  Future<Attendance> markAttendance({
    required int employeeId,
    required DateTime attendanceDate,
    required AttendanceStatus status,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      _basePath,
      authenticated: true,
      body: {
        'employeeId': employeeId,
        'attendanceDate': _formatDate(attendanceDate),
        'status': status.apiValue,
        'reason': _cleanReason(reason),
      },
    );

    return _parseAttendance(response);
  }

  Future<List<Attendance>> markBulkAttendance({
    required DateTime attendanceDate,
    required AttendanceStatus status,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '$_basePath/bulk',
      authenticated: true,
      body: {
        'attendanceDate': _formatDate(attendanceDate),
        'status': status.apiValue,
        'reason': _cleanReason(reason),
      },
    );

    return _parseAttendanceList(response);
  }

  Future<List<Attendance>> getMonthlyAttendance({
    required int year,
    required int month,
  }) async {
    final query = Uri(queryParameters: {'year': '$year', 'month': '$month'})
        .query;

    final response = await _apiClient.get(
      '$_basePath/month?$query',
      authenticated: true,
    );

    return _parseAttendanceList(response);
  }

  Future<List<Attendance>> getEmployeeMonthlyAttendance({
    required int employeeId,
    required int year,
    required int month,
  }) async {
    final query = Uri(queryParameters: {'year': '$year', 'month': '$month'})
        .query;

    final response = await _apiClient.get(
      '$_basePath/employee/$employeeId?$query',
      authenticated: true,
    );

    return _parseAttendanceList(response);
  }

  Future<AttendanceSummary> getDailySummary({required DateTime date}) async {
    final query = Uri(queryParameters: {'date': _formatDate(date)}).query;

    final response = await _apiClient.get(
      '$_basePath/summary/day?$query',
      authenticated: true,
    );

    if (response is! Map) {
      throw const FormatException(
        'The server returned an invalid daily attendance summary.',
      );
    }

    return AttendanceSummary.fromJson(Map<String, dynamic>.from(response));
  }

  Future<List<AttendanceSummary>> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    final query = Uri(queryParameters: {'year': '$year', 'month': '$month'})
        .query;

    final response = await _apiClient.get(
      '$_basePath/summary/month?$query',
      authenticated: true,
    );

    if (response is! List) {
      throw const FormatException(
        'The server returned an invalid monthly attendance summary.',
      );
    }

    return response.map((item) {
      if (item is! Map) {
        throw const FormatException(
          'The server returned an invalid daily summary record.',
        );
      }

      return AttendanceSummary.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<void> deleteAttendance({
    required int attendanceId,
    String? reason,
  }) async {
    final path = _buildQueryPath('$_basePath/$attendanceId', {
      'reason': _cleanReason(reason),
    });

    await _apiClient.delete(path);
  }

  Future<void> deleteEmployeeAttendance({
    required int employeeId,
    required DateTime date,
    String? reason,
  }) async {
    final path = _buildQueryPath('$_basePath/employee/$employeeId', {
      'date': _formatDate(date),
      'reason': _cleanReason(reason),
    });

    await _apiClient.delete(path);
  }

  Future<void> deleteBulkAttendance({
    required DateTime date,
    String? reason,
  }) async {
    final path = _buildQueryPath('$_basePath/bulk', {
      'date': _formatDate(date),
      'reason': _cleanReason(reason),
    });

    await _apiClient.delete(path);
  }

  Attendance _parseAttendance(dynamic response) {
    if (response is! Map) {
      throw const FormatException(
        'The server returned an invalid attendance record.',
      );
    }

    return Attendance.fromJson(Map<String, dynamic>.from(response));
  }

  List<Attendance> _parseAttendanceList(dynamic response) {
    if (response is! List) {
      throw const FormatException(
        'The server returned an invalid attendance list.',
      );
    }

    return response.map((item) {
      if (item is! Map) {
        throw const FormatException(
          'The server returned an invalid attendance record.',
        );
      }

      return Attendance.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  String _buildQueryPath(String path, Map<String, String?> parameters) {
    final filteredParameters = <String, String>{};

    parameters.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        filteredParameters[key] = value;
      }
    });

    if (filteredParameters.isEmpty) return path;

    final query = Uri(queryParameters: filteredParameters).query;

    return '$path?$query';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String? _cleanReason(String? reason) {
    final value = reason?.trim();

    if (value == null || value.isEmpty) return null;

    return value;
  }
}
