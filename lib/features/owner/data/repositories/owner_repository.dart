import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../models/owner_login_response.dart';
import '../models/owner_profile.dart';

class OwnerRepository {
  OwnerRepository(this._api);

  final ApiClient _api;

  Future<OwnerLoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    final result = await _api.post(
      '/api/owners/login',
      body: {'identifier': identifier, 'password': password},
    );

    return OwnerLoginResponse.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<OwnerLoginResponse> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    final result = await _api.post(
      '/api/owners/verify-otp',
      body: {'identifier': identifier, 'otp': otp},
    );

    return OwnerLoginResponse.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<Map<String, dynamic>> register({
    required String ownerName,
    required String organizationName,
    required String email,
    required String mobileNumber,
    required String password,
    required Uint8List logoBytes,
    required String logoFilename,
  }) async {
    final result = await _api.multipart(
      '/api/owners/register',
      method: 'POST',
      request: {
        'ownerName': ownerName,
        'organizationName': organizationName,
        'email': email,
        'mobileNumber': mobileNumber,
        'password': password,
      },
      logoBytes: logoBytes,
      logoFilename: logoFilename,
    );

    return Map<String, dynamic>.from(result as Map);
  }

  Future<OwnerProfile> getProfile() async {
    final result = await _api.get('/api/owners/profile', authenticated: true);

    return OwnerProfile.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<OwnerProfile> updateProfile({
    required Map<String, dynamic> request,
    Uint8List? logoBytes,
    String? logoFilename,
  }) async {
    final result = await _api.multipart(
      '/api/owners/profile',
      method: 'PUT',
      request: request,
      logoBytes: logoBytes,
      logoFilename: logoFilename,
      authenticated: true,
    );

    return OwnerProfile.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<void> deleteLogo() {
    return _api.delete('/api/owners/profile/logo');
  }

  Future<Uint8List> getLogoBytes(int ownerId) {
    return _api.getBytes('/api/owners/$ownerId/logo', authenticated: true);
  }
}
