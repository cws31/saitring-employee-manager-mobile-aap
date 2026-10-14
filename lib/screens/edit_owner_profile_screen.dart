import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/owner_api.dart';

class EditOwnerProfileScreen extends StatefulWidget {
  const EditOwnerProfileScreen({
    super.key,
    required this.token,
    required this.profile,
  });

  final String token;
  final Map<String, dynamic> profile;

  @override
  State<EditOwnerProfileScreen> createState() => _EditOwnerProfileScreenState();
}

class _EditOwnerProfileScreenState extends State<EditOwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _websiteController = TextEditingController();

  final OwnerApi _ownerApi = OwnerApi();
  final ImagePicker _imagePicker = ImagePicker();

  String? _logoPath;
  bool _removeLogo = false;
  bool _isSaving = false;
  bool _isDeletingLogo = false;

  bool get _isBusy => _isSaving || _isDeletingLogo;

  @override
  void initState() {
    super.initState();

    final profile = widget.profile;

    _ownerNameController.text = _read(profile, 'ownerName');
    _organizationController.text = _read(profile, 'organizationName');
    _emailController.text = _read(profile, 'email');
    _mobileController.text = _read(profile, 'mobileNumber');
    _address1Controller.text = _read(profile, 'addressLine1');
    _address2Controller.text = _read(profile, 'addressLine2');
    _cityController.text = _read(profile, 'city');
    _stateController.text = _read(profile, 'state');
    _countryController.text = _read(profile, 'country');
    _postalCodeController.text = _read(profile, 'postalCode');
    _websiteController.text = _read(profile, 'website');
  }

  String _read(Map<String, dynamic> data, String key) {
    return data[key]?.toString() ?? '';
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFE7EDFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.business_outlined,
        color: Color(0xFF2457C5),
        size: 42,
      ),
    );
  }

  Widget _buildExistingLogo() {
    final ownerId = widget.profile['id']?.toString();
    final hasLogo = widget.profile['logoExists'] == true;
    final logoVersion = widget.profile['logoVersion']?.toString();

    if (_removeLogo || !hasLogo || ownerId == null || ownerId.trim().isEmpty) {
      return _buildFallbackLogo();
    }

    final versionQuery = logoVersion == null || logoVersion.isEmpty
        ? ''
        : '?v=${Uri.encodeComponent(logoVersion)}';

    final logoUrl =
        '${ApiConfig.baseUrl}/api/owners/'
        '${Uri.encodeComponent(ownerId)}/logo$versionQuery';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        logoUrl,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'image/*',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EDFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
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

  Future<void> _pickLogo() async {
    if (_isBusy) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (!mounted || image == null) return;

      setState(() {
        _logoPath = image.path;
        _removeLogo = false;
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to select the image. Please try again.');
    }
  }

  Future<void> _saveProfile() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = Map<String, dynamic>.from(widget.profile);

      updatedProfile.addAll({
        'ownerName': _ownerNameController.text.trim(),
        'organizationName': _organizationController.text.trim(),
        'email': _emailController.text.trim(),
        'mobileNumber': _mobileController.text.trim(),
        'addressLine1': _address1Controller.text.trim(),
        'addressLine2': _address2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'website': _websiteController.text.trim(),
      });

      final updated = await _ownerApi.updateProfile(
        token: widget.token,
        profile: updatedProfile,
        logoPath: _logoPath,
      );

      if (!mounted) return;

      // Reflect logo changes immediately in the returned profile.
      final result = <String, dynamic>{...updatedProfile, ...updated};

      if (_logoPath != null) {
        result['logoExists'] = true;
      } else if (_removeLogo) {
        result['logoExists'] = false;
        result['logoVersion'] = null;
      }

      _showMessage('Owner profile updated successfully.');
      Navigator.of(context).pop<Map<String, dynamic>>(result);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to save the profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteLogo() async {
    if (_isBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove organization logo?'),
        content: const Text('This will permanently remove the current logo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeletingLogo = true;
    });

    try {
      await _ownerApi.deleteLogo(token: widget.token);

      if (!mounted) return;

      setState(() {
        _removeLogo = true;
        _logoPath = null;
      });

      _showMessage('Organization logo removed.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to remove the logo. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingLogo = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_isBusy,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _required(value, 'Email');
    if (requiredError != null) return requiredError;

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validateMobile(String? value) {
    final requiredError = _required(value, 'Mobile number');
    if (requiredError != null) return requiredError;

    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value!.trim())) {
      return 'Use international format, e.g. +919876543210.';
    }

    return null;
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Edit Owner Profile'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (_logoPath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_logoPath!),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        _buildExistingLogo(),
                      const SizedBox(height: 12),
                      const Text(
                        'Organization Logo',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isBusy ? null : _pickLogo,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose New Logo'),
                      ),
                      if (_logoPath != null) ...[
                        TextButton(
                          onPressed: _isBusy
                              ? null
                              : () {
                                  setState(() {
                                    _logoPath = null;
                                  });
                                },
                          child: const Text('Cancel New Image'),
                        ),
                      ] else if (!_removeLogo &&
                          widget.profile['logoExists'] == true) ...[
                        TextButton.icon(
                          onPressed: _isBusy ? null : _deleteLogo,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Remove Existing Logo',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Owner Information',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _ownerNameController,
                label: 'Owner Name',
                icon: Icons.person_outline,
                validator: (value) => _required(value, 'Owner name'),
              ),
              _textField(
                controller: _organizationController,
                label: 'Organization Name',
                icon: Icons.business_outlined,
                validator: (value) => _required(value, 'Organization name'),
              ),
              _textField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              _textField(
                controller: _mobileController,
                label: 'Mobile Number (+country code)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _validateMobile,
              ),
              const SizedBox(height: 8),
              const Text(
                'Address',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _address1Controller,
                label: 'Address Line 1',
                icon: Icons.location_on_outlined,
              ),
              _textField(
                controller: _address2Controller,
                label: 'Address Line 2',
                icon: Icons.location_on_outlined,
              ),
              _textField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city_outlined,
              ),
              _textField(
                controller: _stateController,
                label: 'State',
                icon: Icons.map_outlined,
              ),
              _textField(
                controller: _postalCodeController,
                label: 'Postal Code',
                icon: Icons.markunread_mailbox_outlined,
                keyboardType: TextInputType.number,
              ),
              _textField(
                controller: _countryController,
                label: 'Country',
                icon: Icons.public_outlined,
              ),
              const SizedBox(height: 8),
              const Text(
                'Other Details',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _websiteController,
                label: 'Website',
                icon: Icons.language_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isBusy ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2457C5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
