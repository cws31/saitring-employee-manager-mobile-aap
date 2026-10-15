import 'package:http/http.dart' as http;

import '../../models/attendance/attendance.dart';
import '../api_client.dart';

class AttendanceApi {
  AttendanceApi({ApiClient? apiClient, http.Client? httpClient})
    : _apiClient = apiClient ?? ApiClient(httpClient: httpClient);

  final ApiClient _apiClient;

  static const String _basePath = '/api/attendance';

  Future<Attendance> markAttendance({
    required int employeeId,
    required String attendanceDate,
    required AttendanceStatus status,
    required String token,
    String? reason,
  }) async {
    final response = await _apiClient.postJson(
      _basePath,
      token: token,
      body: {
        'employeeId': employeeId,
        'attendanceDate': attendanceDate,
        'status': status.apiValue,
        'reason': reason,
      },
    );

    return Attendance.fromJson(
      _parseObject(
        response,
        'The server did not return a valid attendance record.',
      ),
    );
  }

  Future<List<Attendance>> markBulkAttendance({
    required String attendanceDate,
    required AttendanceStatus status,
    required String token,
    String? reason,
  }) async {
    final response = await _apiClient.postJson(
      '$_basePath/bulk',
      token: token,
      body: {
        'attendanceDate': attendanceDate,
        'status': status.apiValue,
        'reason': reason,
      },
    );

    return Attendance.listFromJson(
      _parseList(
        response,
        'The server did not return a valid attendance list.',
      ),
    );
  }

  Future<List<Attendance>> getMonthlyAttendance({
    required int year,
    required int month,
    required String token,
  }) async {
    final response = await _apiClient.get(
      '$_basePath/month?year=$year&month=$month',
      token: token,
    );

    return Attendance.listFromJson(
      _parseList(
        response,
        'The server did not return a valid attendance list.',
      ),
    );
  }

  Future<List<Attendance>> getEmployeeMonthlyAttendance({
    required int employeeId,
    required int year,
    required int month,
    required String token,
  }) async {
    final response = await _apiClient.get(
      '$_basePath/employee/$employeeId?year=$year&month=$month',
      token: token,
    );

    return Attendance.listFromJson(
      _parseList(
        response,
        'The server did not return a valid employee attendance list.',
      ),
    );
  }

  Future<AttendanceSummary> getDailySummary({
    required String date,
    required String token,
  }) async {
    final response = await _apiClient.get(
      '$_basePath/summary/day?date=$date',
      token: token,
    );

    return AttendanceSummary.fromJson(
      _parseObject(
        response,
        'The server did not return a valid daily attendance summary.',
      ),
    );
  }

  Future<List<AttendanceSummary>> getMonthlySummary({
    required int year,
    required int month,
    required String token,
  }) async {
    final response = await _apiClient.get(
      '$_basePath/summary/month?year=$year&month=$month',
      token: token,
    );

    return AttendanceSummary.listFromJson(
      _parseList(
        response,
        'The server did not return valid monthly attendance summaries.',
      ),
    );
  }

  Future<int> deleteAttendance({
    required int attendanceId,
    required String token,
  }) async {
    final response = await _apiClient.delete(
      '$_basePath/$attendanceId',
      token: token,
    );

    final data = _parseObject(
      response,
      'The server did not return a valid deletion response.',
    );

    final deletedCount = data['deletedCount'];

    if (deletedCount is! num) {
      throw ApiException('The server returned an invalid deletion count.', 200);
    }

    return deletedCount.toInt();
  }

  Future<int> deleteEmployeeAttendance({
    required int employeeId,
    required String date,
    required String token,
  }) async {
    final response = await _apiClient.delete(
      '$_basePath/employee/$employeeId?date=${Uri.encodeQueryComponent(date)}',
      token: token,
    );

    final data = _parseObject(
      response,
      'The server did not return a valid deletion response.',
    );

    final deletedCount = data['deletedCount'];

    if (deletedCount is! num) {
      throw ApiException('The server returned an invalid deletion count.', 200);
    }

    return deletedCount.toInt();
  }

  Future<int> deleteBulkAttendance({
    required String date,
    required String token,
  }) async {
    final response = await _apiClient.delete(
      '$_basePath/bulk?date=${Uri.encodeQueryComponent(date)}',
      token: token,
    );

    final data = _parseObject(
      response,
      'The server did not return a valid bulk deletion response.',
    );

    final deletedCount = data['deletedCount'];

    if (deletedCount is! num) {
      throw ApiException('The server returned an invalid deletion count.', 200);
    }

    return deletedCount.toInt();
  }

  Map<String, dynamic> _parseObject(dynamic response, String errorMessage) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(errorMessage, 200);
  }

  List<dynamic> _parseList(dynamic response, String errorMessage) {
    if (response is List) {
      return response;
    }

    throw ApiException(errorMessage, 200);
  }
}
