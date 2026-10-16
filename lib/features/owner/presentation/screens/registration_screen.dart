// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// import '../../../../core/network/api_client.dart';
// import '../../../../core/network/api_exception.dart';
// import '../../data/repositories/owner_repository.dart';

// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({super.key});

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _ownerName = TextEditingController();
//   final _organization = TextEditingController();
//   final _email = TextEditingController();
//   final _mobile = TextEditingController();
//   final _password = TextEditingController();

//   final _repository = OwnerRepository(ApiClient());

//   Uint8List? _logoBytes;
//   String? _logoFilename;
//   bool _loading = false;
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _ownerName.dispose();
//     _organization.dispose();
//     _email.dispose();
//     _mobile.dispose();
//     _password.dispose();
//     super.dispose();
//   }

//   Future<void> _pickLogo() async {
//     try {
//       final file = await ImagePicker().pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 90,
//       );

//       if (file == null) return;

//       final extension = file.name.split('.').last.toLowerCase();

//       if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
//         _showMessage('Choose a JPEG, PNG or WebP image.');
//         return;
//       }

//       final bytes = await file.readAsBytes();

//       if (bytes.length > 5 * 1024 * 1024) {
//         _showMessage('Logo must not exceed 5 MB.');
//         return;
//       }

//       if (!mounted) return;

//       setState(() {
//         _logoBytes = bytes;
//         _logoFilename = file.name;
//       });
//     } catch (_) {
//       if (mounted) {
//         _showMessage('Unable to select the organization logo.');
//       }
//     }
//   }

//   Future<void> _register() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_logoBytes == null || _logoFilename == null) {
//       _showMessage('Select your organization logo to continue.');
//       return;
//     }

//     setState(() => _loading = true);

//     try {
//       await _repository.register(
//         ownerName: _ownerName.text.trim(),
//         organizationName: _organization.text.trim(),
//         email: _email.text.trim(),
//         mobileNumber: _mobile.text.trim(),
//         password: _password.text,
//         logoBytes: _logoBytes!,
//         logoFilename: _logoFilename!,
//       );

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Registration successful. Please sign in.'),
//         ),
//       );

//       Navigator.pop(context);
//     } on ApiException catch (e) {
//       if (mounted) _showMessage(e.message);
//     } catch (_) {
//       if (mounted) {
//         _showMessage('Unable to register your organization.');
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

//   String? _required(String? value, String label) {
//     if (value == null || value.trim().isEmpty) {
//       return '$label is required';
//     }

//     return null;
//   }

//   Widget _sectionHeading(String title, String subtitle) {
//     final theme = Theme.of(context);
//     final colors = theme.colorScheme;

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             subtitle,
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: colors.onSurfaceVariant,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _decoration({
//     required String label,
//     String? hint,
//     Widget? prefixIcon,
//     Widget? suffixIcon,
//     String? helperText,
//   }) {
//     final colors = Theme.of(context).colorScheme;

//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       helperText: helperText,
//       prefixIcon: prefixIcon,
//       suffixIcon: suffixIcon,
//       filled: true,
//       fillColor: colors.surfaceContainerLow,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: colors.outlineVariant),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: colors.primary, width: 1.5),
//       ),
//       errorMaxLines: 2,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colors = theme.colorScheme;

//     return Scaffold(
//       backgroundColor: colors.surface,
//       appBar: AppBar(
//         title: const Text(
//           'Register organization',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: colors.surface,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: SafeArea(
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
//             children: [
//               Text(
//                 'Create your SEMA account',
//                 style: theme.textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: -0.4,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Enter your details to register your organization.',
//                 style: theme.textTheme.bodyLarge?.copyWith(
//                   color: colors.onSurfaceVariant,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 28),

//               _sectionHeading(
//                 'Owner details',
//                 'Provide the contact details for the account owner.',
//               ),

//               TextFormField(
//                 controller: _ownerName,
//                 enabled: !_loading,
//                 maxLength: 100,
//                 textCapitalization: TextCapitalization.words,
//                 textInputAction: TextInputAction.next,
//                 autofillHints: const [AutofillHints.name],
//                 decoration: _decoration(
//                   label: 'Owner name',
//                   prefixIcon: const Icon(Icons.person_outline),
//                 ),
//                 validator: (value) {
//                   final error = _required(value, 'Owner name');
//                   if (error != null) return error;

//                   if (value!.trim().length < 2) {
//                     return 'Enter at least 2 characters';
//                   }

//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),

//               TextFormField(
//                 controller: _organization,
//                 enabled: !_loading,
//                 maxLength: 150,
//                 textCapitalization: TextCapitalization.words,
//                 textInputAction: TextInputAction.next,
//                 decoration: _decoration(
//                   label: 'Organization name',
//                   prefixIcon: const Icon(Icons.business_outlined),
//                 ),
//                 validator: (value) {
//                   final error = _required(value, 'Organization name');
//                   if (error != null) return error;

//                   if (value!.trim().length < 2) {
//                     return 'Enter at least 2 characters';
//                   }

//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),

//               TextFormField(
//                 controller: _email,
//                 enabled: !_loading,
//                 keyboardType: TextInputType.emailAddress,
//                 maxLength: 150,
//                 textInputAction: TextInputAction.next,
//                 autofillHints: const [AutofillHints.email],
//                 decoration: _decoration(
//                   label: 'Email address',
//                   prefixIcon: const Icon(Icons.email_outlined),
//                 ),
//                 validator: (value) {
//                   final error = _required(value, 'Email');
//                   if (error != null) return error;

//                   if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
//                       .hasMatch(value!.trim())) {
//                     return 'Enter a valid email address';
//                   }

//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),

//               TextFormField(
//                 controller: _mobile,
//                 enabled: !_loading,
//                 keyboardType: TextInputType.phone,
//                 maxLength: 20,
//                 textInputAction: TextInputAction.next,
//                 autofillHints: const [AutofillHints.telephoneNumber],
//                 decoration: _decoration(
//                   label: 'Mobile number',
//                   hint: '+919876543210',
//                   prefixIcon: const Icon(Icons.phone_outlined),
//                   helperText: 'Include the country code, e.g. +91',
//                 ),
//                 validator: (value) {
//                   final error = _required(value, 'Mobile number');
//                   if (error != null) return error;

//                   if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value!.trim())) {
//                     return 'Use international format, e.g. +919876543210';
//                   }

//                   return null;
//                 },
//               ),

//               const SizedBox(height: 12),

//               _sectionHeading(
//                 'Secure your account',
//                 'Choose a password with at least 8 characters.',
//               ),

//               TextFormField(
//                 controller: _password,
//                 enabled: !_loading,
//                 obscureText: _obscurePassword,
//                 maxLength: 100,
//                 textInputAction: TextInputAction.done,
//                 autofillHints: const [AutofillHints.newPassword],
//                 decoration: _decoration(
//                   label: 'Password',
//                   prefixIcon: const Icon(Icons.lock_outline),
//                   suffixIcon: IconButton(
//                     tooltip: _obscurePassword
//                         ? 'Show password'
//                         : 'Hide password',
//                     onPressed: () {
//                       setState(() {
//                         _obscurePassword = !_obscurePassword;
//                       });
//                     },
//                     icon: Icon(
//                       _obscurePassword
//                           ? Icons.visibility_outlined
//                           : Icons.visibility_off_outlined,
//                     ),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.length < 8) {
//                     return 'Password must contain at least 8 characters';
//                   }

//                   return null;
//                 },
//               ),

//               const SizedBox(height: 12),

//               _sectionHeading(
//                 'Organization logo',
//                 'Upload a JPEG, PNG or WebP image up to 5 MB.',
//               ),

//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: colors.surfaceContainerLow,
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(color: colors.outlineVariant),
//                 ),
//                 child: Column(
//                   children: [
//                     if (_logoBytes != null) ...[
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Image.memory(
//                           _logoBytes!,
//                           height: 120,
//                           width: 120,
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                     ] else ...[
//                       Container(
//                         width: 64,
//                         height: 64,
//                         decoration: BoxDecoration(
//                           color: colors.primaryContainer,
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Icon(
//                           Icons.add_photo_alternate_outlined,
//                           size: 30,
//                           color: colors.onPrimaryContainer,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                     ],
//                     Text(
//                       _logoFilename ?? 'No logo selected',
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton.icon(
//                         onPressed: _loading ? null : _pickLogo,
//                         icon: const Icon(Icons.photo_library_outlined),
//                         label: Text(
//                           _logoBytes == null ? 'Choose logo' : 'Change logo',
//                         ),
//                       ),
//                     ),
//                     if (_logoBytes == null) ...[
//                       const SizedBox(height: 8),
//                       Text(
//                         'Required to register your organization',
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: colors.onSurfaceVariant,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 28),

//               SizedBox(
//                 height: 52,
//                 child: FilledButton(
//                   onPressed: _loading ? null : _register,
//                   style: FilledButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: _loading
//                       ? const SizedBox(
//                           height: 22,
//                           width: 22,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text('Create organization'),
//                             SizedBox(width: 8),
//                             Icon(Icons.arrow_forward_rounded, size: 18),
//                           ],
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/owner_repository.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerName = TextEditingController();
  final _organization = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();

  final _repository = OwnerRepository(ApiClient());

  Uint8List? _logoBytes;
  String? _logoFilename;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ownerName.dispose();
    _organization.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (file == null) return;

      final extension = file.name.split('.').last.toLowerCase();

      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        _showMessage('Choose a JPEG, PNG or WebP image.');
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('Logo must not exceed 5 MB.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _logoBytes = bytes;
        _logoFilename = file.name;
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to select the organization logo.');
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_logoBytes == null || _logoFilename == null) {
      _showMessage('Select your organization logo to continue.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _repository.register(
        ownerName: _ownerName.text.trim(),
        organizationName: _organization.text.trim(),
        email: _email.text.trim(),
        mobileNumber: _mobile.text.trim(),
        password: _password.text,
        logoBytes: _logoBytes!,
        logoFilename: _logoFilename!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful. Please sign in.'),
        ),
      );

      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to register your organization.');
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

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  Widget _sectionHeading(String title, String subtitle) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 1.8),
      ),
      errorMaxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Register organization',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              Text(
                'Create your SEMA account',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your details to register your organization.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Owner Details Card Block
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeading(
                      'Owner details',
                      'Provide the contact details for the account owner.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerName,
                      enabled: !_loading,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: _decoration(
                        label: 'Owner name',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        final error = _required(value, 'Owner name');
                        if (error != null) return error;

                        if (value!.trim().length < 2) {
                          return 'Enter at least 2 characters';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organization,
                      enabled: !_loading,
                      maxLength: 150,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(
                        label: 'Organization name',
                        prefixIcon: const Icon(Icons.business_outlined),
                      ),
                      validator: (value) {
                        final error = _required(value, 'Organization name');
                        if (error != null) return error;

                        if (value!.trim().length < 2) {
                          return 'Enter at least 2 characters';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 150,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: _decoration(
                        label: 'Email address',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final error = _required(value, 'Email');
                        if (error != null) return error;

                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value!.trim())) {
                          return 'Enter a valid email address';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobile,
                      enabled: !_loading,
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: _decoration(
                        label: 'Mobile number',
                        hint: '+919876543210',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        helperText: 'Include country code, e.g. +91',
                      ),
                      validator: (value) {
                        final error = _required(value, 'Mobile number');
                        if (error != null) return error;

                        if (!RegExp(r'^\+[1-9]\d{7,14}$')
                            .hasMatch(value!.trim())) {
                          return 'Use international format, e.g. +919876543210';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security Card Block
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeading(
                      'Secure your account',
                      'Choose a password with at least 8 characters.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_loading,
                      obscureText: _obscurePassword,
                      maxLength: 100,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _decoration(
                        label: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
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
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Password must contain at least 8 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Organization Logo Card Block
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _sectionHeading(
                      'Organization logo',
                      'Upload a JPEG, PNG or WebP image up to 5 MB.',
                    ),
                    const SizedBox(height: 16),
                    if (_logoBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          _logoBytes!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 30,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      _logoFilename ?? 'No logo selected',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _pickLogo,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        icon: Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                        label: Text(
                          _logoBytes == null ? 'Choose logo' : 'Change logo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (_logoBytes == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Required to register your organization',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _register,
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
                              'Create organization',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
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
