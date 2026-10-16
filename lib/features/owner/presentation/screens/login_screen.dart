// import 'package:flutter/material.dart';

// import '../../../../core/network/api_client.dart';
// import '../../../../core/network/api_exception.dart';
// import '../../data/repositories/owner_repository.dart';
// import 'otp_screen.dart';
// import 'registration_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _identifier = TextEditingController();
//   final _password = TextEditingController();

//   final _repository = OwnerRepository(ApiClient());

//   bool _loading = false;
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _identifier.dispose();
//     _password.dispose();
//     super.dispose();
//   }

//   Future<void> _login() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _loading = true);

//     try {
//       final result = await _repository.login(
//         identifier: _identifier.text.trim(),
//         password: _password.text,
//       );

//       if (!mounted) return;

//       if (result.otpRequired) {
//         Navigator.push(
//           context,
//           MaterialPageRoute<void>(
//             builder: (_) => OtpScreen(identifier: _identifier.text.trim()),
//           ),
//         );

//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text(result.message)));
//       } else {
//         throw const ApiException(
//           message: 'Unexpected login response from the server.',
//           statusCode: 500,
//         );
//       }
//     } on ApiException catch (e) {
//       if (mounted) _showMessage(e.message);
//     } catch (_) {
//       if (mounted) {
//         _showMessage('Unable to complete login.');
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _loading = false);
//       }
//     }
//   }

//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colors = theme.colorScheme;

//     return Scaffold(
//       backgroundColor: colors.surface,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 400),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const SizedBox(height: 12),

//                     // Brand
//                     Center(
//                       child: Container(
//                         width: 68,
//                         height: 68,
//                         decoration: BoxDecoration(
//                           color: colors.primaryContainer,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Icon(
//                           Icons.business_rounded,
//                           size: 34,
//                           color: colors.onPrimaryContainer,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     Text(
//                       'Welcome to SEMA',
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: -0.5,
//                         color: colors.onSurface,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Sign in to manage your organization.',
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.bodyLarge?.copyWith(
//                         color: colors.onSurfaceVariant,
//                       ),
//                     ),
//                     const SizedBox(height: 36),

//                     // Email or mobile number
//                     Text(
//                       'Email or mobile number',
//                       style: theme.textTheme.labelLarge?.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: _identifier,
//                       keyboardType: TextInputType.emailAddress,
//                       textInputAction: TextInputAction.next,
//                       autofillHints: const [AutofillHints.username],
//                       decoration: InputDecoration(
//                         hintText: 'Enter your email or mobile number',
//                         prefixIcon: const Icon(Icons.person_outline),
//                         filled: true,
//                         fillColor: colors.surfaceContainerLow,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: colors.outlineVariant),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: colors.outlineVariant),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(
//                             color: colors.primary,
//                             width: 1.5,
//                           ),
//                         ),
//                         errorMaxLines: 2,
//                       ),
//                       validator: (value) {
//                         if (value == null || value.trim().isEmpty) {
//                           return 'Enter your email or mobile number';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 20),

//                     // Password
//                     Text(
//                       'Password',
//                       style: theme.textTheme.labelLarge?.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: _password,
//                       obscureText: _obscurePassword,
//                       textInputAction: TextInputAction.done,
//                       autofillHints: const [AutofillHints.password],
//                       onFieldSubmitted: (_) {
//                         if (!_loading) _login();
//                       },
//                       decoration: InputDecoration(
//                         hintText: 'Enter your password',
//                         prefixIcon: const Icon(Icons.lock_outline),
//                         suffixIcon: IconButton(
//                           tooltip: _obscurePassword
//                               ? 'Show password'
//                               : 'Hide password',
//                           onPressed: () {
//                             setState(() {
//                               _obscurePassword = !_obscurePassword;
//                             });
//                           },
//                           icon: Icon(
//                             _obscurePassword
//                                 ? Icons.visibility_outlined
//                                 : Icons.visibility_off_outlined,
//                           ),
//                         ),
//                         filled: true,
//                         fillColor: colors.surfaceContainerLow,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: colors.outlineVariant),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: colors.outlineVariant),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(
//                             color: colors.primary,
//                             width: 1.5,
//                           ),
//                         ),
//                         errorMaxLines: 2,
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Enter your password';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 28),

//                     // Primary action
//                     SizedBox(
//                       height: 52,
//                       child: FilledButton(
//                         onPressed: _loading ? null : _login,
//                         style: FilledButton.styleFrom(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: _loading
//                             ? const SizedBox(
//                                 height: 22,
//                                 width: 22,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : const Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text('Continue'),
//                                   SizedBox(width: 8),
//                                   Icon(Icons.arrow_forward_rounded, size: 18),
//                                 ],
//                               ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     // Registration
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Flexible(
//                           child: Text(
//                             "Don't have an account?",
//                             style: theme.textTheme.bodyMedium?.copyWith(
//                               color: colors.onSurfaceVariant,
//                             ),
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: _loading
//                               ? null
//                               : () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute<void>(
//                                       builder: (_) =>
//                                           const RegistrationScreen(),
//                                     ),
//                                   );
//                                 },
//                           child: const Text('Register'),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/owner_repository.dart';
import 'otp_screen.dart';
import 'registration_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  final _repository = OwnerRepository(ApiClient());

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final result = await _repository.login(
        identifier: _identifier.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;

      if (result.otpRequired) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => OtpScreen(identifier: _identifier.text.trim()),
          ),
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message)));
      } else {
        throw const ApiException(
          message: 'Unexpected login response from the server.',
          statusCode: 500,
        );
      }
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to complete login.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
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
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: colors.surfaceContainerLow.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // Brand Icon
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.business_rounded,
                              size: 36,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title & Subtitle
                        Text(
                          'Welcome to SEMA',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure Portal Access • Manage Your Organization',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Email or mobile number
                        Text(
                          'Email or Mobile Number',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _identifier,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(
                            hintText: 'Enter your email or mobile',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: colors.primary.withValues(alpha: 0.8),
                            ),
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.outlineVariant,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 1.8,
                              ),
                            ),
                            errorMaxLines: 2,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter your email or mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password
                        Text(
                          'Password',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) {
                            if (!_loading) _login();
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: colors.primary.withValues(alpha: 0.8),
                            ),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.outlineVariant,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 1.8,
                              ),
                            ),
                            errorMaxLines: 2,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Primary action button
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _loading ? null : _login,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _loading
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onPrimary,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Registration link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                "Don't have an account?",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const RegistrationScreen(),
                                        ),
                                      );
                                    },
                              child: const Text(
                                'Register',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
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
