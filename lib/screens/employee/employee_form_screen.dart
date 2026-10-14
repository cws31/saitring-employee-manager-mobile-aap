import 'package:flutter/material.dart';

import '../../models/employee/employee.dart';
import '../../services/api_client.dart';
import '../../services/employee/employee_api.dart';

const Color _primaryBlue = Color(0xFF2457C5);
const Color _pageBackground = Color(0xFFF5F7FB);
const Color _borderColor = Color(0xFFE0E5EF);

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key, required this.token, this.employee});

  final String token;
  final Employee? employee;

  bool get isEditing => employee != null;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _rateController = TextEditingController();

  final EmployeeApi _employeeApi = EmployeeApi();

  bool _isSubmitting = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();

    final employee = widget.employee;

    if (employee != null) {
      _nameController.text = employee.name;
      _mobileController.text = employee.mobile;
      _rateController.text = employee.initialRate.toStringAsFixed(2);
    } else {
      _rateController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Employee name is required.';
    }

    if (name.length > 100) {
      return 'Name cannot exceed 100 characters.';
    }

    return null;
  }

  String? _validateMobile(String? value) {
    final mobile = value?.trim() ?? '';

    if (mobile.isEmpty) {
      return 'Mobile number is required.';
    }

    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(mobile)) {
      return 'Enter 10–15 digits, optionally starting with +.';
    }

    return null;
  }

  String? _validateRate(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter a rate, or 0 if not applicable.';
    }

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
      return 'Enter a valid amount with up to 2 decimal places.';
    }

    final rate = double.tryParse(text);

    if (rate == null || !rate.isFinite) {
      return 'Enter a valid amount.';
    }

    if (rate < 0) {
      return 'Initial rate cannot be negative.';
    }

    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    final rate = double.parse(_rateController.text.trim());

    setState(() {
      _isSubmitting = true;
      _apiError = null;
    });

    try {
      if (widget.isEditing) {
        await _employeeApi.updateEmployee(
          id: widget.employee!.id,
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          initialRate: rate,
          token: widget.token,
        );
      } else {
        await _employeeApi.createEmployee(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          initialRate: rate,
          token: widget.token,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            widget.isEditing
                ? 'Employee updated successfully.'
                : 'Employee registered successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _apiError = error.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _apiError = 'Something went wrong. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          isEditing ? 'Edit Employee' : 'Add Employee',
          style: const TextStyle(
            color: Color(0xFF182230),
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        leading: IconButton(
          tooltip: 'Go back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              _buildHeader(isEditing),
              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF182230),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Fields marked with * are required.',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                    const SizedBox(height: 22),

                    _buildFieldLabel('Employee name *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 100,
                      enabled: !_isSubmitting,
                      validator: _validateName,
                      onChanged: (_) => _clearApiError(),
                      decoration: _inputDecoration(
                        hint: 'Enter full name',
                        icon: Icons.person_outline,
                      ),
                    ),

                    const SizedBox(height: 14),
                    _buildFieldLabel('Mobile number *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      maxLength: 16,
                      enabled: !_isSubmitting,
                      validator: _validateMobile,
                      onChanged: (_) => _clearApiError(),
                      decoration: _inputDecoration(
                        hint: 'e.g. 9876543210',
                        icon: Icons.phone_outlined,
                      ),
                    ),

                    const SizedBox(height: 14),
                    _buildFieldLabel('Initial rate (₹) *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      enabled: !_isSubmitting,
                      validator: _validateRate,
                      onChanged: (_) => _clearApiError(),
                      onFieldSubmitted: (_) {
                        if (!_isSubmitting) _submit();
                      },
                      decoration: _inputDecoration(
                        hint: '0.00',
                        icon: Icons.currency_rupee,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Enter 0 if no initial rate applies.',
                      style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                    ),
                  ],
                ),
              ),

              if (_apiError != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(_apiError!),
              ],

              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    disabledBackgroundColor: _primaryBlue.withValues(
                      alpha: 0.65,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 11),
                            Text(
                              'Please wait...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEditing
                                  ? Icons.save_outlined
                                  : Icons.person_add_alt_1,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              isEditing ? 'Save changes' : 'Register employee',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              if (!_isSubmitting)
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF475467),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEditing ? Icons.edit_outlined : Icons.person_add_alt_1,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Update employee' : 'New employee',
                  style: const TextStyle(
                    color: Color(0xFF183B83),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isEditing
                      ? 'Update the details and save your changes.'
                      : 'Add an employee to your organisation.',
                  style: const TextStyle(
                    color: Color(0xFF475D85),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF344054),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF912018),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearApiError() {
    if (_apiError == null) return;

    setState(() {
      _apiError = null;
    });
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF667085), size: 21),
      filled: true,
      fillColor: const Color(0xFFFCFCFD),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD92D20)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.5),
      ),
    );
  }
}
