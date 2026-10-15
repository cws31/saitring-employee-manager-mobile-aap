class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://personal-business.onrender.com';

  static const String ownerRegister = '/api/owners/register';
  static const String ownerLogin = '/api/owners/login';
  static const String ownerVerifyOtp = '/api/owners/verify-otp';
  static const String ownerProfile = '/api/owners/profile';

  static const String employees = '/api/employees';

  static String employeeById(int id) => '$employees/$id';

  static String employeeToggleBlock(int id) => '$employees/$id/toggle-block';

  static const String attendance = '/api/attendance';

  static String attendanceEmployee(int employeeId) =>
      '$attendance/employee/$employeeId';

  static const String attendanceBulk = '$attendance/bulk';
  static const String attendanceMonth = '$attendance/month';
  static const String attendanceDailySummary = '$attendance/summary/day';
  static const String attendanceMonthlySummary = '$attendance/summary/month';
}
