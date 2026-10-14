import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiClient {
  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Uri _buildUri(String endpoint) {
    return Uri.parse('${ApiConfig.baseUrl}$endpoint');
  }

  Map<String, String> _buildHeaders({String? token, bool jsonContent = false}) {
    return {
      'Accept': 'application/json',
      if (jsonContent) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint, {String? token}) async {
    final response = await _httpClient.get(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token),
    );

    return _handleResponse(response);
  }

  Future<dynamic> postJson(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await _httpClient.post(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token, jsonContent: true),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> putJson(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await _httpClient.put(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token, jsonContent: true),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> patchJson(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await _httpClient.patch(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token, jsonContent: true),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, {String? token}) async {
    final response = await _httpClient.patch(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {String? token}) async {
    final response = await _httpClient.delete(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token),
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final responseBody = utf8.decode(response.bodyBytes);
    final trimmedBody = responseBody.trim();

    dynamic data;

    if (trimmedBody.isNotEmpty) {
      try {
        data = jsonDecode(trimmedBody);
      } on FormatException {
        // Some endpoints return plain text instead of JSON.
        data = trimmedBody;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    var message = 'Request failed. Please try again.';

    if (data is Map<String, dynamic>) {
      final serverMessage = data['message'];

      if (serverMessage is String && serverMessage.isNotEmpty) {
        message = serverMessage;
      } else {
        final error = data['error'];

        if (error is String && error.isNotEmpty) {
          message = error;
        }
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    throw ApiException(message, response.statusCode);
  }

  void close() {
    _httpClient.close();
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
