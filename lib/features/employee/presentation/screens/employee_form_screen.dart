import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/employee.dart';
import '../../data/repositories/employee_repository.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key, this.employee});

  final Employee? employee;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _rateController = TextEditingController();

  final EmployeeRepository _repository = EmployeeRepository(ApiClient());

  DateTime? _joiningDate;
  bool _saving = false;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();

    final employee = widget.employee;

    if (employee != null) {
      _nameController.text = employee.name;
      _mobileController.text = employee.mobile;
      _rateController.text = employee.initialRate.toStringAsFixed(2);
      _joiningDate = employee.joiningDate;
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

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee name is required.';
    }

    if (value.trim().length > 100) {
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
    final rate = double.tryParse(text);

    if (text.isEmpty || rate == null) {
      return 'Enter a valid initial rate.';
    }

    if (!rate.isFinite || rate < 0) {
      return 'Initial rate must be zero or positive.';
    }

    if (rate > 99999999.99) {
      return 'Initial rate is too large.';
    }

    if (text.contains('.') && text.split('.').last.length > 2) {
      return 'Use at most two decimal places.';
    }

    return null;
  }

  Future<void> _selectJoiningDate(FormFieldState<DateTime> field) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate = _joiningDate ?? today;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(today) ? today : initialDate,
      firstDate: DateTime(1950),
      lastDate: today,
      helpText: 'Select actual joining date',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _joiningDate = DateUtils.dateOnly(selectedDate);
      });

      field.didChange(_joiningDate);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final joiningDate = _joiningDate;

    if (joiningDate == null) return;

    final rate = double.parse(_rateController.text.trim());

    setState(() {
      _saving = true;
    });

    try {
      if (_isEditing) {
        await _repository.updateEmployee(
          id: widget.employee!.id,
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          initialRate: rate,
          joiningDate: _formatDate(joiningDate),
        );
      } else {
        await _repository.createEmployee(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          initialRate: rate,
          joiningDate: _formatDate(joiningDate),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      final message = error is ApiException
          ? error.message
          : error is FormatException
          ? error.message
          : 'Unable to save employee. Please try again.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit employee' : 'Add employee'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isEditing
                          ? Icons.edit_note_rounded
                          : Icons.person_add_alt_1_rounded,
                      size: 32,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Update employee details'
                            : 'Enter the new employee details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Employee name',
                  hintText: 'Enter full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _mobileController,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                maxLength: 16,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  hintText: '10–15 digits',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateMobile,
              ),
              const SizedBox(height: 16),

              FormField<DateTime>(
                validator: (_) {
                  if (_joiningDate == null) {
                    return 'Joining date is required.';
                  }
                  return null;
                },
                builder: (field) {
                  final date = _joiningDate;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _saving ? null : () => _selectJoiningDate(field),
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Joining date',
                            hintText: 'Select actual joining date',
                            prefixIcon: const Icon(
                              Icons.calendar_month_outlined,
                            ),
                            suffixIcon: const Icon(
                              Icons.arrow_drop_down_rounded,
                            ),
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                          ),
                          child: Text(
                            date == null
                                ? 'Select actual joining date'
                                : _formatDate(date),
                            style: TextStyle(
                              color: date == null
                                  ? colors.onSurfaceVariant
                                  : colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Use the employee’s actual first working date.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _rateController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Initial rate',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                  border: OutlineInputBorder(),
                  helperText: 'Enter zero or a positive amount.',
                ),
                validator: _validateRate,
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : _isEditing
                        ? 'Update employee'
                        : 'Save employee',
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
