// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// import '../../../../core/network/api_client.dart';
// import '../../../../core/network/api_exception.dart';
// import '../../data/models/owner_profile.dart';
// import '../../data/repositories/owner_repository.dart';

// class OwnerProfileScreen extends StatefulWidget {
//   const OwnerProfileScreen({super.key, required this.profile});

//   final OwnerProfile profile;

//   @override
//   State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
// }

// class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _repository = OwnerRepository(ApiClient());

//   late final Map<String, TextEditingController> _fields;

//   Uint8List? _logoBytes;
//   String? _logoFilename;
//   bool _loading = false;
//   bool _logoDeleted = false;

//   @override
//   void initState() {
//     super.initState();

//     final p = widget.profile;

//     _fields = {
//       'ownerName': TextEditingController(text: p.ownerName),
//       'organizationName': TextEditingController(text: p.organizationName),
//       'email': TextEditingController(text: p.email),
//       'mobileNumber': TextEditingController(text: p.mobileNumber),
//       'addressLine1': TextEditingController(text: p.addressLine1 ?? ''),
//       'addressLine2': TextEditingController(text: p.addressLine2 ?? ''),
//       'city': TextEditingController(text: p.city ?? ''),
//       'state': TextEditingController(text: p.state ?? ''),
//       'country': TextEditingController(text: p.country ?? ''),
//       'postalCode': TextEditingController(text: p.postalCode ?? ''),
//       'website': TextEditingController(text: p.website ?? ''),
//     };
//   }

//   @override
//   void dispose() {
//     for (final controller in _fields.values) {
//       controller.dispose();
//     }
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
//         _logoDeleted = false;
//       });
//     } catch (_) {
//       if (mounted) {
//         _showMessage('Unable to select the organization logo.');
//       }
//     }
//   }

//   Future<void> _deleteLogo() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete organization logo?'),
//         content: const Text('The current logo will be permanently removed.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete logo'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed != true || !mounted) return;

//     setState(() => _loading = true);

//     try {
//       await _repository.deleteLogo();

//       if (!mounted) return;

//       setState(() {
//         _logoDeleted = true;
//         _logoBytes = null;
//         _logoFilename = null;
//       });

//       _showMessage('Organization logo deleted.');
//     } on ApiException catch (e) {
//       if (mounted) _showMessage(e.message);
//     } catch (_) {
//       if (mounted) {
//         _showMessage('Unable to delete the logo.');
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _loading = false);
//       }
//     }
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _loading = true);

//     try {
//       final request = <String, dynamic>{};

//       for (final entry in _fields.entries) {
//         request[entry.key] = entry.value.text.trim();
//       }

//       for (final key in [
//         'addressLine1',
//         'addressLine2',
//         'city',
//         'state',
//         'country',
//         'postalCode',
//         'website',
//       ]) {
//         if ((request[key] as String).isEmpty) {
//           request[key] = null;
//         }
//       }

//       await _repository.updateProfile(
//         request: request,
//         logoBytes: _logoBytes,
//         logoFilename: _logoFilename,
//       );

//       if (!mounted) return;

//       _showMessage('Profile updated successfully.');
//       Navigator.pop(context);
//     } on ApiException catch (e) {
//       if (mounted) _showMessage(e.message);
//     } catch (_) {
//       if (mounted) {
//         _showMessage('Unable to update the profile.');
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

//   Widget _field(
//     String key,
//     String label, {
//     TextInputType? keyboardType,
//     bool required = false,
//     String? Function(String?)? validator,
//     TextInputAction? textInputAction,
//   }) {
//     final colors = Theme.of(context).colorScheme;

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: TextFormField(
//         controller: _fields[key],
//         keyboardType: keyboardType,
//         textInputAction: textInputAction ?? TextInputAction.next,
//         enabled: !_loading,
//         decoration: InputDecoration(
//           labelText: label,
//           filled: true,
//           fillColor: colors.surfaceContainerLow,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: colors.outlineVariant),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: colors.primary, width: 1.5),
//           ),
//           errorMaxLines: 2,
//         ),
//         validator:
//             validator ??
//             (value) {
//               if (required && (value == null || value.trim().isEmpty)) {
//                 return '$label is required';
//               }

//               return null;
//             },
//       ),
//     );
//   }

//   Widget _buildLogoSection() {
//     final theme = Theme.of(context);
//     final colors = theme.colorScheme;
//     final hasExistingLogo = widget.profile.logoExists && !_logoDeleted;

//     Widget logoPreview;

//     if (_logoBytes != null) {
//       logoPreview = CircleAvatar(
//         radius: 44,
//         backgroundColor: colors.primaryContainer,
//         backgroundImage: MemoryImage(_logoBytes!),
//       );
//     } else if (hasExistingLogo) {
//       logoPreview = FutureBuilder<Uint8List>(
//         future: _repository.getLogoBytes(widget.profile.id),
//         builder: (context, snapshot) {
//           if (snapshot.hasData) {
//             return CircleAvatar(
//               radius: 44,
//               backgroundColor: colors.primaryContainer,
//               backgroundImage: MemoryImage(snapshot.data!),
//             );
//           }

//           if (snapshot.hasError) {
//             return CircleAvatar(
//               radius: 44,
//               backgroundColor: colors.primaryContainer,
//               child: Icon(
//                 Icons.business_outlined,
//                 size: 34,
//                 color: colors.onPrimaryContainer,
//               ),
//             );
//           }

//           return CircleAvatar(
//             radius: 44,
//             backgroundColor: colors.primaryContainer,
//             child: const SizedBox(
//               width: 24,
//               height: 24,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           );
//         },
//       );
//     } else {
//       logoPreview = CircleAvatar(
//         radius: 44,
//         backgroundColor: colors.primaryContainer,
//         child: Icon(
//           Icons.business_outlined,
//           size: 34,
//           color: colors.onPrimaryContainer,
//         ),
//       );
//     }

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: colors.surfaceContainerLow,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         children: [
//           logoPreview,
//           const SizedBox(height: 12),
//           Text(
//             'Organization logo',
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'JPEG, PNG or WebP · Maximum 5 MB',
//             textAlign: TextAlign.center,
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: colors.onSurfaceVariant,
//             ),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: OutlinedButton.icon(
//               onPressed: _loading ? null : _pickLogo,
//               icon: const Icon(Icons.photo_library_outlined),
//               label: Text(
//                 _logoFilename == null ? 'Choose image' : 'Change image',
//               ),
//             ),
//           ),
//           if (hasExistingLogo) ...[
//             const SizedBox(height: 4),
//             TextButton.icon(
//               onPressed: _loading ? null : _deleteLogo,
//               icon: const Icon(Icons.delete_outline, size: 18),
//               label: const Text('Remove current logo'),
//               style: TextButton.styleFrom(foregroundColor: colors.error),
//             ),
//           ],
//         ],
//       ),
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
//           'Organization profile',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: colors.surface,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
//           children: [
//             Text(
//               'Keep your details up to date',
//               style: theme.textTheme.bodyLarge?.copyWith(
//                 color: colors.onSurfaceVariant,
//               ),
//             ),
//             const SizedBox(height: 24),

//             _buildLogoSection(),

//             const SizedBox(height: 32),

//             _sectionHeading(
//               'Basic information',
//               'Your name and organization contact details.',
//             ),
//             _field('ownerName', 'Owner name', required: true),
//             _field('organizationName', 'Organization name', required: true),
//             _field(
//               'email',
//               'Email address',
//               required: true,
//               keyboardType: TextInputType.emailAddress,
//               validator: (value) {
//                 if (value == null || value.trim().isEmpty) {
//                   return 'Email is required';
//                 }

//                 if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
//                     .hasMatch(value.trim())) {
//                   return 'Enter a valid email address';
//                 }

//                 return null;
//               },
//             ),
//             _field(
//               'mobileNumber',
//               'Mobile number',
//               required: true,
//               keyboardType: TextInputType.phone,
//             ),

//             const SizedBox(height: 12),

//             _sectionHeading('Address', 'Address details are optional.'),
//             _field('addressLine1', 'Address line 1'),
//             _field('addressLine2', 'Address line 2'),
//             _field('city', 'City'),
//             _field('state', 'State'),
//             _field('country', 'Country'),
//             _field(
//               'postalCode',
//               'Postal code',
//               keyboardType: TextInputType.number,
//             ),

//             const SizedBox(height: 12),

//             _sectionHeading(
//               'Online presence',
//               'Add your organization website if available.',
//             ),
//             _field(
//               'website',
//               'Website URL',
//               keyboardType: TextInputType.url,
//               textInputAction: TextInputAction.done,
//             ),

//             const SizedBox(height: 12),

//             SizedBox(
//               height: 52,
//               child: FilledButton(
//                 onPressed: _loading ? null : _save,
//                 style: FilledButton.styleFrom(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: _loading
//                     ? const SizedBox(
//                         height: 22,
//                         width: 22,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Text('Save changes'),
//               ),
//             ),
//           ],
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
import '../../data/models/owner_profile.dart';
import '../../data/repositories/owner_repository.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key, required this.profile});

  final OwnerProfile profile;

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = OwnerRepository(ApiClient());

  late final Map<String, TextEditingController> _fields;

  Uint8List? _logoBytes;
  String? _logoFilename;
  bool _loading = false;
  bool _logoDeleted = false;

  @override
  void initState() {
    super.initState();

    final p = widget.profile;

    _fields = {
      'ownerName': TextEditingController(text: p.ownerName),
      'organizationName': TextEditingController(text: p.organizationName),
      'email': TextEditingController(text: p.email),
      'mobileNumber': TextEditingController(text: p.mobileNumber),
      'addressLine1': TextEditingController(text: p.addressLine1 ?? ''),
      'addressLine2': TextEditingController(text: p.addressLine2 ?? ''),
      'city': TextEditingController(text: p.city ?? ''),
      'state': TextEditingController(text: p.state ?? ''),
      'country': TextEditingController(text: p.country ?? ''),
      'postalCode': TextEditingController(text: p.postalCode ?? ''),
      'website': TextEditingController(text: p.website ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
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
        _logoDeleted = false;
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to select the organization logo.');
      }
    }
  }

  Future<void> _deleteLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete organization logo?'),
        content: const Text('The current logo will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete logo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);

    try {
      await _repository.deleteLogo();

      if (!mounted) return;

      setState(() {
        _logoDeleted = true;
        _logoBytes = null;
        _logoFilename = null;
      });

      _showMessage('Organization logo deleted.');
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to delete the logo.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final request = <String, dynamic>{};

      for (final entry in _fields.entries) {
        request[entry.key] = entry.value.text.trim();
      }

      for (final key in [
        'addressLine1',
        'addressLine2',
        'city',
        'state',
        'country',
        'postalCode',
        'website',
      ]) {
        if ((request[key] as String).isEmpty) {
          request[key] = null;
        }
      }

      await _repository.updateProfile(
        request: request,
        logoBytes: _logoBytes,
        logoFilename: _logoFilename,
      );

      if (!mounted) return;

      _showMessage('Profile updated successfully.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to update the profile.');
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

  Widget _field(
    String key,
    String label, {
    TextInputType? keyboardType,
    bool required = false,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _fields[key],
        keyboardType: keyboardType,
        textInputAction: textInputAction ?? TextInputAction.next,
        enabled: !_loading,
        decoration: InputDecoration(
          labelText: label,
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
        ),
        validator:
            validator ??
            (value) {
              if (required && (value == null || value.trim().isEmpty)) {
                return '$label is required';
              }
              return null;
            },
      ),
    );
  }

  Widget _buildLogoSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasExistingLogo = widget.profile.logoExists && !_logoDeleted;

    Widget logoPreview;

    if (_logoBytes != null) {
      logoPreview = CircleAvatar(
        radius: 46,
        backgroundColor: colors.primaryContainer,
        backgroundImage: MemoryImage(_logoBytes!),
      );
    } else if (hasExistingLogo) {
      logoPreview = FutureBuilder<Uint8List>(
        future: _repository.getLogoBytes(widget.profile.id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 46,
              backgroundColor: colors.primaryContainer,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          }

          if (snapshot.hasError) {
            return CircleAvatar(
              radius: 46,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.business_outlined,
                size: 36,
                color: colors.onPrimaryContainer,
              ),
            );
          }

          return CircleAvatar(
            radius: 46,
            backgroundColor: colors.primaryContainer,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onPrimaryContainer,
              ),
            ),
          );
        },
      );
    } else {
      logoPreview = CircleAvatar(
        radius: 46,
        backgroundColor: colors.primaryContainer,
        child: Icon(
          Icons.business_outlined,
          size: 36,
          color: colors.onPrimaryContainer,
        ),
      );
    }

    return Container(
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
          logoPreview,
          const SizedBox(height: 14),
          Text(
            'Organization logo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'JPEG, PNG or WebP • Maximum 5 MB',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
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
                _logoFilename == null ? 'Choose image' : 'Change image',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          if (hasExistingLogo) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loading ? null : _deleteLogo,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Remove current logo'),
              style: TextButton.styleFrom(
                foregroundColor: colors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
          ],
        ],
      ),
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
          'Organization profile',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            Text(
              'Keep your organization details up to date for smooth management and reporting.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Logo section card
            _buildLogoSection(),
            const SizedBox(height: 24),

            // Basic information section
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
                    'Basic information',
                    'Your name and organization contact details.',
                  ),
                  const SizedBox(height: 16),
                  _field('ownerName', 'Owner name', required: true),
                  _field(
                    'organizationName',
                    'Organization name',
                    required: true,
                  ),
                  _field(
                    'email',
                    'Email address',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  _field(
                    'mobileNumber',
                    'Mobile number',
                    required: true,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Address section
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
                    'Address',
                    'Physical address details are optional.',
                  ),
                  const SizedBox(height: 16),
                  _field('addressLine1', 'Address line 1'),
                  _field('addressLine2', 'Address line 2'),
                  _field('city', 'City'),
                  _field('state', 'State'),
                  _field('country', 'Country'),
                  _field(
                    'postalCode',
                    'Postal code',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Online presence section
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
                    'Online presence',
                    'Add your organization website if available.',
                  ),
                  const SizedBox(height: 16),
                  _field(
                    'website',
                    'Website URL',
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save changes button
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _save,
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
                    : const Text(
                        'Save changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
