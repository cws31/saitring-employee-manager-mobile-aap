import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/employee/employee.dart';
import '../api_client.dart';

class EmployeeApi {
  EmployeeApi({ApiClient? apiClient, http.Client? httpClient})
    : _apiClient = apiClient ?? ApiClient(httpClient: httpClient);

  final ApiClient _apiClient;

  Future<List<Employee>> getEmployees({required String token}) async {
    final response = await _apiClient.get(ApiConfig.employees, token: token);

    return Employee.listFromJson(response);
  }

  Future<Employee> getEmployee({required int id, required String token}) async {
    final response = await _apiClient.get(
      ApiConfig.employeeById(id),
      token: token,
    );

    return _parseEmployee(response);
  }

  Future<Employee> createEmployee({
    required String name,
    required String mobile,
    required String token,
    double initialRate = 0,
  }) async {
    final response = await _apiClient.postJson(
      ApiConfig.employees,
      token: token,
      body: {'name': name, 'mobile': mobile, 'initialRate': initialRate},
    );

    return _parseEmployee(response);
  }

  Future<Employee> updateEmployee({
    required int id,
    required String name,
    required String mobile,
    required String token,
    double initialRate = 0,
  }) async {
    final response = await _apiClient.putJson(
      ApiConfig.employeeById(id),
      token: token,
      body: {'name': name, 'mobile': mobile, 'initialRate': initialRate},
    );

    return _parseEmployee(response);
  }

  Future<void> deleteEmployee({required int id, required String token}) async {
    await _apiClient.delete(ApiConfig.employeeById(id), token: token);
  }

  Future<Employee> toggleBlockStatus({
    required int id,
    required String token,
  }) async {
    final response = await _apiClient.patch(
      ApiConfig.employeeToggleBlock(id),
      token: token,
    );

    return _parseEmployee(response);
  }

  Employee _parseEmployee(dynamic response) {
    if (response is Map<String, dynamic>) {
      return Employee.fromJson(response);
    }

    throw ApiException(
      'The server did not return a valid employee record.',
      200,
    );
  }
}
