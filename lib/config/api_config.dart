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
}
