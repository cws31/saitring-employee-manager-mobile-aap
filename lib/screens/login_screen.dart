import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../services/token_storage.dart';
import 'owner_dashboard_screen.dart';
import 'owner_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  final AuthApi _authApi = AuthApi();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _otpRequired = false;

  String? _errorMessage;
  String? _successMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _authApi.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response['otpRequired'] == true) {
        setState(() {
          _otpRequired = true;
          _successMessage =
              response['message']?.toString() ??
              'OTP sent. Check your email or phone.';
        });
      } else {
        setState(() {
          _errorMessage =
              'Unexpected login response. OTP verification was not requested.';
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to connect to the server. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() {
        _errorMessage = 'Enter a valid 6-digit OTP.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _authApi.verifyOtp(
        identifier: _identifierController.text.trim(),
        otp: otp,
      );

      if (!mounted) return;

      final token = response['token']?.toString();
      final otpRequired = response['otpRequired'] == true;

      if (token == null || token.trim().isEmpty || otpRequired) {
        setState(() {
          _errorMessage =
              'OTP verification did not return a valid login token.';
        });
        return;
      }

      // Save the JWT before navigating to the dashboard.
      await _tokenStorage.saveToken(token);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OwnerDashboardScreen(token: token),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Login could not be completed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _backToLogin() {
    setState(() {
      _otpRequired = false;
      _otpController.clear();
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _openRegistration() async {
    if (_isLoading) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OwnerRegistrationScreen()),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 3,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          size: 54,
                          color: Color(0xFF2457C5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SAITRING',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _otpRequired
                              ? 'Verify your identity'
                              : 'Employee Manager',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),

                        if (!_otpRequired) ...[
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Email or mobile number',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your email or mobile number.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isLoading ? null : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2457C5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            "Don't have an owner account?",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _openRegistration,
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('Create Owner Account'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2457C5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Enter the 6-digit OTP sent to '
                            '${_identifierController.text.trim()}.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            enabled: !_isLoading,
                            decoration: const InputDecoration(
                              labelText: '6-digit OTP',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2457C5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Verify OTP'),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _backToLogin,
                            child: const Text('Back to login'),
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],

                        if (_successMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _successMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
