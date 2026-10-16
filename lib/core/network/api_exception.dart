class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.statusCode,
    this.errors = const {},
  });

  final String message;
  final int statusCode;
  final Map<String, String> errors;

  factory ApiException.fromResponse(int statusCode, dynamic body) {
    if (body is Map<String, dynamic>) {
      final rawErrors = body['errors'];
      final errors = <String, String>{};

      if (rawErrors is Map) {
        rawErrors.forEach((key, value) {
          errors[key.toString()] = value.toString();
        });
      }

      return ApiException(
        message:
            body['message']?.toString() ??
            'Request failed with status $statusCode.',
        statusCode: statusCode,
        errors: errors,
      );
    }

    return ApiException(
      message: 'Request failed with status $statusCode.',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}
