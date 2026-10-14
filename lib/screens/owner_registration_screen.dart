import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/auth_api.dart';

class OwnerRegistrationScreen extends StatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  State<OwnerRegistrationScreen> createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authApi = AuthApi();
  final _imagePicker = ImagePicker();

  final _ownerNameController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  XFile? _selectedLogo;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _organizationNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (!mounted || image == null) return;

      setState(() {
        _selectedLogo = image;
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to select the logo. Please try again.');
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _validateRequired(value, 'Email');
    if (requiredError != null) return requiredError;

    final email = value!.trim();
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validateMobile(String? value) {
    final requiredError = _validateRequired(value, 'Mobile number');

    if (requiredError != null) return requiredError;

    // Example: +919876543210
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value!.trim())) {
      return 'Enter your number with country code, e.g. +919876543210.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final requiredError = _validateRequired(value, 'Password');

    if (requiredError != null) return requiredError;

    if (value!.length < 8) {
      return 'Password must contain at least 8 characters.';
    }

    return null;
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLogo == null) {
      _showMessage('Please select your organization logo.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authApi.registerOwner(
        ownerName: _ownerNameController.text.trim(),
        organizationName: _organizationNameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        password: _passwordController.text,
        logoPath: _selectedLogo!.path,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful. You can now log in.'),
        ),
      );

      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } on ArgumentError catch (error) {
      if (!mounted) return;
      _showMessage(error.message?.toString() ?? 'Invalid input.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Registration failed. Check your connection and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Owner Registration')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Create your owner account',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your owner and organization details.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Organization Logo'),
              const SizedBox(height: 12),

              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _selectedLogo == null
                          ? const Icon(Icons.business, size: 48)
                          : Image.file(
                              File(_selectedLogo!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickLogo,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _selectedLogo == null ? 'Select Logo *' : 'Change Logo',
                      ),
                    ),
                    const Text(
                      'Selecting a logo is required.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Owner Details'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _ownerNameController,
                label: 'Owner Name *',
                icon: Icons.person_outline,
                validator: (value) => _validateRequired(value, 'Owner name'),
                textCapitalization: TextCapitalization.words,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address *',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hintText: '+919876543210',
                validator: _validateMobile,
              ),
              _buildTextField(
                controller: _passwordController,
                label: 'Password *',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                validator: _validatePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _buildSectionTitle('Organization Details'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _organizationNameController,
                label: 'Organization Name *',
                icon: Icons.business_outlined,
                validator: (value) =>
                    _validateRequired(value, 'Organization name'),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 8),
              Text('* Required fields', style: theme.textTheme.bodySmall),
              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitRegistration,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register Owner'),
                ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        enabled: !_isSubmitting,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
