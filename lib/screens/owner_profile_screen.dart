import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/owner_api.dart';
import '../services/token_storage.dart';
import 'edit_owner_profile_screen.dart';
import 'login_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key, required this.token});

  final String token;

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  late final OwnerApi _ownerApi;
  final TokenStorage _tokenStorage = TokenStorage();

  Map<String, dynamic>? _profile;

  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ownerApi = OwnerApi();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _ownerApi.getProfile(token: widget.token);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        try {
          await _tokenStorage.deleteToken();
        } catch (_) {
          if (!mounted) return;

          setState(() {
            _errorMessage =
                'Your session has expired, but sign-out failed. '
                'Please try again.';
            _isLoading = false;
          });
          return;
        }

        if (!mounted) return;

        _goToLogin();
        return;
      }

      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load the Owner profile. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _value(String key) {
    final value = _profile?[key];

    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }

    return value.toString();
  }

  String _address() {
    const fields = [
      'addressLine1',
      'addressLine2',
      'city',
      'state',
      'postalCode',
      'country',
    ];

    final parts = fields
        .map((key) => _profile?[key]?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();

    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  Widget _buildFallbackLogo() {
    return const CircleAvatar(
      radius: 38,
      backgroundColor: Color(0xFFE7EDFF),
      child: Icon(Icons.business, color: Color(0xFF2457C5), size: 38),
    );
  }

  Widget _buildOwnerLogo() {
    final ownerId = _profile?['id']?.toString();
    final hasLogo = _profile?['logoExists'] == true;
    final logoVersion = _profile?['logoVersion']?.toString();

    if (!hasLogo || ownerId == null || ownerId.trim().isEmpty) {
      return _buildFallbackLogo();
    }

    final versionQuery = logoVersion == null || logoVersion.isEmpty
        ? ''
        : '?v=${Uri.encodeComponent(logoVersion)}';

    final logoUrl =
        '${ApiConfig.baseUrl}/api/owners/'
        '${Uri.encodeComponent(ownerId)}/logo$versionQuery';

    return ClipOval(
      child: Image.network(
        logoUrl,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'image/*',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const SizedBox(
            width: 76,
            height: 76,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2457C5),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLogo();
        },
      ),
    );
  }

  Future<void> _editProfile() async {
    final currentProfile = _profile;

    if (currentProfile == null || _isLoading || _isLoggingOut) {
      return;
    }

    final updatedProfile = await Navigator.of(context)
        .push<Map<String, dynamic>>(
          MaterialPageRoute<Map<String, dynamic>>(
            builder: (_) => EditOwnerProfileScreen(
              token: widget.token,
              profile: Map<String, dynamic>.from(currentProfile),
            ),
          ),
        );

    if (!mounted || updatedProfile == null) return;

    setState(() {
      _profile = {...currentProfile, ...updatedProfile};
    });

    // Reload the authoritative profile and refresh the logo version.
    await _loadProfile();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to log out of your account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _tokenStorage.deleteToken();

      if (!mounted) return;

      _goToLogin();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  Widget _profileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2457C5), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = _value('ownerName');
    final organizationName = _value('organizationName');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Owner Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _isLoading || _isLoggingOut ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _isLoggingOut ? null : _confirmLogout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _loadProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadProfile,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildOwnerLogo(),
                            const SizedBox(height: 16),
                            Text(
                              ownerName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              organizationName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Chip(
                              avatar: Icon(
                                Icons.verified_user,
                                size: 17,
                                color: Color(0xFF2457C5),
                              ),
                              label: Text('Authenticated Owner'),
                              backgroundColor: Color(0xFFE7EDFF),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _editProfile,
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Profile'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2457C5),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 1,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 28),
                            _profileItem(
                              icon: Icons.person_outline,
                              label: 'Owner Name',
                              value: ownerName,
                            ),
                            _profileItem(
                              icon: Icons.business_outlined,
                              label: 'Organization',
                              value: organizationName,
                            ),
                            _profileItem(
                              icon: Icons.email_outlined,
                              label: 'Email Address',
                              value: _value('email'),
                            ),
                            _profileItem(
                              icon: Icons.phone_outlined,
                              label: 'Mobile Number',
                              value: _value('mobileNumber'),
                            ),
                            _profileItem(
                              icon: Icons.location_on_outlined,
                              label: 'Address',
                              value: _address(),
                            ),
                            _profileItem(
                              icon: Icons.language_outlined,
                              label: 'Website',
                              value: _value('website'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
