import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_client.dart';

class OwnerApi {
  OwnerApi({ApiClient? apiClient, http.Client? httpClient})
    : _apiClient = apiClient ?? ApiClient(),
      _httpClient = httpClient ?? http.Client();

  final ApiClient _apiClient;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> getProfile({required String token}) async {
    final response = await _apiClient.get(ApiConfig.ownerProfile, token: token);

    return _asMap(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required Map<String, dynamic> profile,
    String? logoPath,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ownerProfile}'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.files.add(
      http.MultipartFile.fromString(
        'request',
        jsonEncode(profile),
        contentType: _jsonMediaType,
      ),
    );

    if (logoPath != null && logoPath.trim().isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('logo', logoPath));
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    return _asMap(_handleMultipartResponse(response));
  }

  Future<void> deleteLogo({required String token}) async {
    final response = await _apiClient.delete(
      '${ApiConfig.ownerProfile}/logo',
      token: token,
    );

    if (response != null &&
        response is! Map<String, dynamic> &&
        response is! List) {
      throw ApiException('Unexpected response received from the server.', 200);
    }
  }

  Map<String, dynamic> _handleMultipartResponse(http.Response response) {
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
      if (data == null) {
        return <String, dynamic>{};
      }

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw ApiException(
        'Unexpected response received from the server.',
        response.statusCode,
      );
    }

    var message = 'Request failed. Please try again.';

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

  static final http.MediaType _jsonMediaType = http.MediaType(
    'application',
    'json',
  );
}
