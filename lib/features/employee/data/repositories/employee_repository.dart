import '../../../../core/network/api_client.dart';
import '../models/employee.dart';

class EmployeeRepository {
  EmployeeRepository(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/api/employees';

  Future<List<Employee>> getEmployees() async {
    final response = await _apiClient.get(_basePath, authenticated: true);

    if (response is! List) {
      throw const FormatException(
        'The server returned an invalid employee list.',
      );
    }

    return response.map((item) {
      if (item is! Map) {
        throw const FormatException(
          'The server returned an invalid employee record.',
        );
      }

      return Employee.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<Employee> getEmployee(int id) async {
    final response = await _apiClient.get(
      '$_basePath/$id',
      authenticated: true,
    );

    return _parseEmployee(response);
  }

  Future<Employee> createEmployee({
    required String name,
    required String mobile,
    required double initialRate,
    required String joiningDate,
  }) async {
    final response = await _apiClient.post(
      _basePath,
      authenticated: true,
      body: {
        'name': name,
        'mobile': mobile,
        'initialRate': initialRate,
        'joiningDate': joiningDate,
      },
    );

    return _parseEmployee(response);
  }

  Future<Employee> updateEmployee({
    required int id,
    required String name,
    required String mobile,
    required double initialRate,
    required String joiningDate,
  }) async {
    final response = await _apiClient.put(
      '$_basePath/$id',
      authenticated: true,
      body: {
        'name': name,
        'mobile': mobile,
        'initialRate': initialRate,
        'joiningDate': joiningDate,
      },
    );

    return _parseEmployee(response);
  }

  Future<void> deleteEmployee(int id) async {
    await _apiClient.delete('$_basePath/$id');
  }

  Future<Employee> toggleBlock(int id) async {
    final response = await _apiClient.patch('$_basePath/$id/toggle-block');

    return _parseEmployee(response);
  }

  Employee _parseEmployee(dynamic response) {
    if (response is! Map) {
      throw const FormatException(
        'The server returned an invalid employee record.',
      );
    }

    return Employee.fromJson(Map<String, dynamic>.from(response));
  }
}
