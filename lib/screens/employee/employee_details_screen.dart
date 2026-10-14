import 'package:flutter/material.dart';

import '../../models/employee/employee.dart';
import '../../services/api_client.dart';
import '../../services/employee/employee_api.dart';
import 'employee_form_screen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  const EmployeeDetailsScreen({
    super.key,
    required this.token,
    required this.employee,
    this.onEmployeeChanged,
  });

  final String token;
  final Employee employee;
  final ValueChanged<Employee>? onEmployeeChanged;

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  final EmployeeApi _employeeApi = EmployeeApi();

  late Employee _employee;
  bool _isUpdatingStatus = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
  }

  Future<void> _editEmployee() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            EmployeeFormScreen(token: widget.token, employee: _employee),
      ),
    );

    if (!mounted || updated != true) return;

    try {
      final refreshed = await _employeeApi.getEmployee(
        id: _employee.id,
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        _employee = refreshed;
        _errorMessage = null;
      });

      widget.onEmployeeChanged?.call(refreshed);
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not refresh employee details.')),
      );
    }
  }

  Future<void> _toggleBlockStatus() async {
    if (_isUpdatingStatus || _isDeleting) return;

    final action = _employee.blocked ? 'unblock' : 'block';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${action == 'block' ? 'Block' : 'Unblock'} employee?'),
        content: Text('Are you sure you want to $action ${_employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action == 'block' ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isUpdatingStatus = true;
      _errorMessage = null;
    });

    try {
      final updated = await _employeeApi.toggleBlockStatus(
        id: _employee.id,
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        _employee = updated;
        _isUpdatingStatus = false;
      });

      widget.onEmployeeChanged?.call(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.blocked
                ? 'Employee blocked successfully.'
                : 'Employee unblocked successfully.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isUpdatingStatus = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isUpdatingStatus = false;
        _errorMessage = 'Could not update employee status. Please try again.';
      });
    }
  }

  Future<void> _deleteEmployee() async {
    if (_isDeleting || _isUpdatingStatus) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Employee?'),
        content: Text(
          'Are you sure you want to delete ${_employee.name}? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await _employeeApi.deleteEmployee(id: _employee.id, token: widget.token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deleted successfully.')),
      );

      // Return true so the employee list refreshes.
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
        _errorMessage = 'Could not delete employee. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = _isUpdatingStatus || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        actions: [
          IconButton(
            tooltip: 'Edit employee',
            onPressed: isBusy ? null : _editEmployee,
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            enabled: !isBusy,
            onSelected: (value) {
              if (value == 'delete') {
                _deleteEmployee();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Employee',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 38,
            child: Text(
              _employee.name.trim().isEmpty
                  ? '?'
                  : _employee.name.trim()[0].toUpperCase(),
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _employee.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Center(
            child: Chip(
              avatar: Icon(
                _employee.blocked ? Icons.block : Icons.check_circle_outline,
                size: 18,
              ),
              label: Text(_employee.blocked ? 'Blocked' : 'Active'),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _detailRow(
                  icon: Icons.badge_outlined,
                  label: 'Employee ID',
                  value: _employee.id.toString(),
                ),
                const Divider(height: 1),
                _detailRow(
                  icon: Icons.phone_outlined,
                  label: 'Mobile number',
                  value: _employee.mobile,
                ),
                const Divider(height: 1),
                _detailRow(
                  icon: Icons.currency_rupee,
                  label: 'Initial rate',
                  value: '₹${_employee.initialRate.toStringAsFixed(2)}',
                ),
                if (_employee.createdAt != null) ...[
                  const Divider(height: 1),
                  _detailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Created on',
                    value: _formatDate(_employee.createdAt!),
                  ),
                ],
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: isBusy ? null : _toggleBlockStatus,
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _employee.blocked
                        ? Icons.lock_open_outlined
                        : Icons.block_outlined,
                  ),
            label: Text(
              _isDeleting
                  ? 'Deleting...'
                  : _isUpdatingStatus
                  ? 'Updating...'
                  : _employee.blocked
                  ? 'Unblock Employee'
                  : 'Block Employee',
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}
