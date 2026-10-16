// import 'package:flutter/material.dart';

// import '../../../../core/network/api_client.dart';
// import '../../../../core/network/api_exception.dart';
// import '../../../../core/storage/token_storage.dart';
// import '../../data/repositories/owner_repository.dart';
// import 'owner_home_screen.dart';

// class OtpScreen extends StatefulWidget {
//   const OtpScreen({super.key, required this.identifier});

//   final String identifier;

//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }

// class _OtpScreenState extends State<OtpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _otp = TextEditingController();
//   final _repository = OwnerRepository(ApiClient());

//   bool _loading = false;

//   @override
//   void dispose() {
//     _otp.dispose();
//     super.dispose();
//   }

//   Future<void> _verify() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _loading = true);

//     try {
//       final result = await _repository.verifyOtp(
//         identifier: widget.identifier,
//         otp: _otp.text.trim(),
//       );

//       final token = result.token;
//       final ownerId = result.ownerId;

//       if (token == null || token.isEmpty || ownerId == null) {
//         throw const ApiException(
//           message: 'The server did not return a valid session.',
//           statusCode: 500,
//         );
//       }

//       await TokenStorage.saveSession(token: token, ownerId: ownerId.toString());

//       if (!mounted) return;

//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute<void>(builder: (_) => const OwnerHomeScreen()),
//         (_) => false,
//       );
//     } on ApiException catch (e) {
//       if (mounted) {
//         _showMessage(e.message);
//       }
//     } catch (_) {
//       if (mounted) {
//         _showMessage('Unable to verify the code.');
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
//       appBar: AppBar(
//         title: const Text('Verify your identity'),
//         backgroundColor: colors.surface,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 400),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 68,
//                         height: 68,
//                         decoration: BoxDecoration(
//                           color: colors.primaryContainer,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Icon(
//                           Icons.mark_email_read_outlined,
//                           size: 34,
//                           color: colors.onPrimaryContainer,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 28),
//                     Text(
//                       'Check your messages',
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: -0.5,
//                         color: colors.onSurface,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Enter the six-digit verification code sent to your '
//                       'registered email address or mobile number.',
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.bodyLarge?.copyWith(
//                         height: 1.5,
//                         color: colors.onSurfaceVariant,
//                       ),
//                     ),
//                     const SizedBox(height: 32),
//                     Text(
//                       'Verification code',
//                       style: theme.textTheme.labelLarge?.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: _otp,
//                       keyboardType: TextInputType.number,
//                       textInputAction: TextInputAction.done,
//                       autofillHints: const [AutofillHints.oneTimeCode],
//                       maxLength: 6,
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.headlineSmall?.copyWith(
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: 8,
//                       ),
//                       onFieldSubmitted: (_) {
//                         if (!_loading) _verify();
//                       },
//                       decoration: InputDecoration(
//                         hintText: '••••••',
//                         hintStyle: TextStyle(
//                           color: colors.onSurfaceVariant.withValues(alpha: 0.5),
//                           letterSpacing: 8,
//                         ),
//                         counterText: '',
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
//                         if (value == null ||
//                             !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
//                           return 'Enter the six-digit verification code';
//                         }

//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       height: 52,
//                       child: FilledButton(
//                         onPressed: _loading ? null : _verify,
//                         style: FilledButton.styleFrom(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: _loading
//                             ? const SizedBox(
//                                 width: 22,
//                                 height: 22,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : const Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text('Verify and sign in'),
//                                   SizedBox(width: 8),
//                                   Icon(Icons.arrow_forward_rounded, size: 18),
//                                 ],
//                               ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Text(
//                       'For your security, the verification code expires '
//                       'after a limited time.',
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         height: 1.5,
//                         color: colors.onSurfaceVariant,
//                       ),
//                     ),
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
import '../../../../core/storage/token_storage.dart';
import '../../data/repositories/owner_repository.dart';
import 'owner_home_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.identifier});

  final String identifier;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _repository = OwnerRepository(ApiClient());

  bool _loading = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final result = await _repository.verifyOtp(
        identifier: widget.identifier,
        otp: _otp.text.trim(),
      );

      final token = result.token;
      final ownerId = result.ownerId;

      if (token == null || token.isEmpty || ownerId == null) {
        throw const ApiException(
          message: 'The server did not return a valid session.',
          statusCode: 500,
        );
      }

      await TokenStorage.saveSession(token: token, ownerId: ownerId.toString());

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const OwnerHomeScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) {
        _showMessage(e.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to verify the code.');
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
      appBar: AppBar(
        title: const Text('Verify your identity'),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                        // Brand / Security Icon
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
                              Icons.mark_email_read_outlined,
                              size: 36,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Check your messages',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle with existing identifier info
                        Text(
                          'Enter the six-digit verification code sent to your registered account.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Meaningful summary chip displaying target identifier
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.identifier,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colors.onSurface,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Label
                        Text(
                          'Verification code',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // OTP Input Field
                        TextFormField(
                          controller: _otp,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 8,
                            color: colors.onSurface,
                          ),
                          onFieldSubmitted: (_) {
                            if (!_loading) _verify();
                          },
                          decoration: InputDecoration(
                            hintText: '••••••',
                            hintStyle: TextStyle(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                              letterSpacing: 8,
                            ),
                            counterText: '',
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
                            if (value == null ||
                                !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                              return 'Enter the six-digit verification code';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Action Button
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _loading ? null : _verify,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _loading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onPrimary,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Verify and sign in',
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
                        const SizedBox(height: 20),

                        // Footer security note
                        Text(
                          'For your security, the verification code expires after a limited time.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5,
                            color: colors.onSurfaceVariant,
                          ),
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
