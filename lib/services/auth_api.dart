import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_client.dart';

class AuthApi {
  AuthApi({ApiClient? apiClient, http.Client? httpClient})
    : _apiClient = apiClient ?? ApiClient(),
      _httpClient = httpClient ?? http.Client();

  final ApiClient _apiClient;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> registerOwner({
    required String ownerName,
    required String organizationName,
    required String email,
    required String mobileNumber,
    required String password,
    required String logoPath,
  }) async {
    if (logoPath.trim().isEmpty) {
      throw ArgumentError('Owner logo is required.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ownerRegister}'),
    );

    request.headers['Accept'] = 'application/json';

    request.files.add(
      http.MultipartFile.fromString(
        'request',
        jsonEncode({
          'ownerName': ownerName.trim(),
          'organizationName': organizationName.trim(),
          'email': email.trim(),
          'mobileNumber': mobileNumber.trim(),
          'password': password,
        }),
        contentType: http.MediaType('application', 'json'),
      ),
    );

    request.files.add(await http.MultipartFile.fromPath('logo', logoPath));

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      ApiConfig.ownerLogin,
      body: {'identifier': identifier.trim(), 'password': password},
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    final response = await _apiClient.postJson(
      ApiConfig.ownerVerifyOtp,
      body: {'identifier': identifier.trim(), 'otp': otp.trim()},
    );

    return _asMap(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    dynamic data;

    if (body.trim().isNotEmpty) {
      try {
        data = jsonDecode(body);
      } on FormatException {
        throw ApiException(
          'The server returned an invalid response.',
          response.statusCode,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _asMap(data);
    }

    var message = 'Registration failed. Please try again.';

    if (data is Map<String, dynamic>) {
      final serverMessage = data['message'];

      if (serverMessage is String && serverMessage.isNotEmpty) {
        message = serverMessage;
      }
    }

    throw ApiException(message, response.statusCode);
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException('Unexpected response received from the server.', 200);
  }
}
