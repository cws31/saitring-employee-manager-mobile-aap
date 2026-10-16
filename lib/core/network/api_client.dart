import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient();

  Future<Map<String, String>> _headers({bool authenticated = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};

    if (authenticated) {
      final token = await TokenStorage.readToken();

      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Your session has expired. Please log in again.',
          statusCode: 401,
        );
      }

      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  dynamic _decode(http.Response response) {
    final body = response.body;
    dynamic data;

    if (body.isNotEmpty) {
      try {
        data = jsonDecode(body);
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response.statusCode, data);
    }

    return data;
  }

  Future<dynamic> get(String path, {bool authenticated = false}) async {
    try {
      final response = await http
          .get(
            _uri(path),
            headers: await _headers(authenticated: authenticated),
          )
          .timeout(ApiConfig.timeout);

      return _decode(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond.',
        statusCode: 408,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Unable to connect to the server.',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = false,
  }) async {
    try {
      final response = await http
          .post(
            _uri(path),
            headers: {
              ...await _headers(authenticated: authenticated),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      return _decode(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond.',
        statusCode: 408,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Unable to connect to the server.',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> multipart(
    String path, {
    required Map<String, dynamic> request,
    required String method,
    Uint8List? logoBytes,
    String? logoFilename,
    bool authenticated = false,
  }) async {
    final multipartRequest = http.MultipartRequest(method, _uri(path));

    multipartRequest.headers.addAll(
      await _headers(authenticated: authenticated),
    );

    multipartRequest.files.add(
      http.MultipartFile.fromString(
        'request',
        jsonEncode(request),
        contentType: MediaType('application', 'json'),
      ),
    );

    if (logoBytes != null && logoFilename != null) {
      final extension = logoFilename.split('.').last.toLowerCase();

      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
        'png' => MediaType('image', 'png'),
        'webp' => MediaType('image', 'webp'),
        _ => throw const ApiException(
          message: 'Choose a JPEG, PNG or WebP image.',
          statusCode: 400,
        ),
      };

      multipartRequest.files.add(
        http.MultipartFile.fromBytes(
          'logo',
          logoBytes,
          filename: logoFilename,
          contentType: mimeType,
        ),
      );
    }

    try {
      final streamed = await multipartRequest.send().timeout(ApiConfig.timeout);

      final response = await http.Response.fromStream(streamed);

      return _decode(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond.',
        statusCode: 408,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Unable to connect to the server.',
        statusCode: 0,
      );
    }
  }

  Future<void> delete(String path, {bool authenticated = true}) async {
    try {
      final response = await http
          .delete(
            _uri(path),
            headers: await _headers(authenticated: authenticated),
          )
          .timeout(ApiConfig.timeout);

      _decode(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond.',
        statusCode: 408,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Unable to connect to the server.',
        statusCode: 0,
      );
    }
  }

  Future<Uint8List> getBytes(String path, {bool authenticated = false}) async {
    try {
      final response = await http
          .get(
            _uri(path),
            headers: await _headers(authenticated: authenticated),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        dynamic body;

        try {
          body = jsonDecode(response.body);
        } catch (_) {
          body = null;
        }

        throw ApiException.fromResponse(response.statusCode, body);
      }

      return response.bodyBytes;
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond.',
        statusCode: 408,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Unable to connect to the server.',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> put(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = true,
  }) async {
    try {
      final response = await http
          .put(
            _uri(path),
            headers: {
              ...await _headers(authenticated: authenticated),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      return _decode(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond.',
        statusCode: 408,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Unable to connect to the server.',
        statusCode: 0,
      );
    }
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic> body = const {},
    bool authenticated = true,
  }) async {
    try {
      final response = await http
          .patch(
            _uri(path),
            headers: {
              ...await _headers(authenticated: authenticated),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      return _decode(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond.',
        statusCode: 408,
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Unable to connect to the server.',
        statusCode: 0,
      );
    }
  }
}
