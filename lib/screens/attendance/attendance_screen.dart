import 'package:flutter/material.dart';

import '../../models/attendance/attendance.dart';
import '../../models/employee/employee.dart';
import '../../services/api_client.dart';
import '../../services/attendance/attendance_api.dart';
import '../../services/employee/employee_api.dart';
import 'attendance_history_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.token});

  final String token;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const Color _primaryBlue = Color(0xFF2457C5);
  static const Color _pageBackground = Color(0xFFF5F7FB);
  static const Color _textPrimary = Color(0xFF17233B);
  static const Color _textSecondary = Color(0xFF667085);
  static const Color _green = Color(0xFF237443);
  static const Color _red = Color(0xFFB42318);
  static const Color _orange = Color(0xFFB54708);

  final EmployeeApi _employeeApi = EmployeeApi();
  final AttendanceApi _attendanceApi = AttendanceApi();

  DateTime _selectedDate = DateTime.now();

  List<Employee> _employees = [];
  final Map<int, AttendanceStatus> _selectedStatuses = {};
  final Map<int, Attendance> _savedRecords = {};
  final Set<int> _savingEmployeeIds = {};

  bool _isLoading = true;
  bool _isBulkSaving = false;
  bool _isBulkDeleting = false;
  final Set<int> _deletingEmployeeIds = {};
  String? _errorMessage;

  int get _presentCount => _selectedStatuses.values
      .where((status) => status == AttendanceStatus.present)
      .length;

  int get _absentCount => _selectedStatuses.values
      .where((status) => status == AttendanceStatus.absent)
      .length;

  int get _halfDayCount => _selectedStatuses.values
      .where((status) => status == AttendanceStatus.halfDay)
      .length;

  int get _unmarkedCount => _employees.length - _selectedStatuses.length;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _displayDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> _loadData() async {
    if (!mounted || _isBulkSaving) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employees = await _employeeApi.getEmployees(token: widget.token);

      final records = await _attendanceApi.getMonthlyAttendance(
        year: _selectedDate.year,
        month: _selectedDate.month,
        token: widget.token,
      );

      if (!mounted) return;

      // Blocked employees must never appear in the attendance list.
      final activeEmployees =
          employees.where((employee) => !employee.blocked).toList()..sort(
            (first, second) =>
                first.name.toLowerCase().compareTo(second.name.toLowerCase()),
          );

      final activeEmployeeIds = activeEmployees
          .map((employee) => employee.id)
          .toSet();

      final statuses = <int, AttendanceStatus>{};
      final savedRecords = <int, Attendance>{};

      for (final record in records) {
        if (_isSameDate(record.attendanceDate, _selectedDate) &&
            activeEmployeeIds.contains(record.employeeId)) {
          savedRecords[record.employeeId] = record;
          statuses[record.employeeId] = record.status;
        }
      }

      setState(() {
        _employees = activeEmployees;
        _selectedStatuses
          ..clear()
          ..addAll(statuses);
        _savedRecords
          ..clear()
          ..addAll(savedRecords);
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } on FormatException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to load attendance. Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    if (_isBulkSaving || _isBulkDeleting) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select attendance date',
    );

    if (pickedDate == null || !mounted) return;
    if (_isSameDate(pickedDate, _selectedDate)) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });

    await _loadData();
  }

  void _selectStatus(int employeeId, AttendanceStatus status) {
    if (_isBulkSaving ||
        _isBulkDeleting ||
        _deletingEmployeeIds.contains(employeeId)) {
      return;
    }

    setState(() {
      _selectedStatuses[employeeId] = status;
    });
  }

  Future<void> _saveAttendance(Employee employee) async {
    final status = _selectedStatuses[employee.id];

    if (status == null ||
        _isBulkSaving ||
        _isBulkDeleting ||
        _deletingEmployeeIds.contains(employee.id) ||
        _savingEmployeeIds.contains(employee.id)) {
      return;
    }

    setState(() {
      _savingEmployeeIds.add(employee.id);
    });

    try {
      final record = await _attendanceApi.markAttendance(
        employeeId: employee.id,
        attendanceDate: _formatDate(_selectedDate),
        status: status,
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        _savedRecords[employee.id] = record;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${employee.name}: ${status.displayName} saved successfully.',
          ),
          backgroundColor: _green,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: _red),
      );
    } on FormatException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: _red),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save attendance. Please try again.'),
          backgroundColor: _red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingEmployeeIds.remove(employee.id);
        });
      }
    }
  }

  Future<void> _clearEmployeeAttendance(Employee employee) async {
    if (_isBulkSaving ||
        _isBulkDeleting ||
        _savingEmployeeIds.isNotEmpty ||
        _deletingEmployeeIds.isNotEmpty) {
      return;
    }

    final record = _savedRecords[employee.id];
    if (record == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear attendance?'),
        content: Text(
          "Permanently delete ${employee.name}'s attendance for "
          '${_displayDate(_selectedDate)}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete attendance'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingEmployeeIds.add(employee.id);
    });

    try {
      final deletedCount = await _attendanceApi.deleteAttendance(
        attendanceId: record.id,
        token: widget.token,
      );

      if (!mounted) return;

      await _loadData();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deletedCount > 0
                ? "${employee.name}'s attendance was deleted."
                : 'No attendance record was deleted.',
          ),
          backgroundColor: deletedCount > 0 ? _green : _orange,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: _red),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: _red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete attendance. Please try again.'),
          backgroundColor: _red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingEmployeeIds.remove(employee.id);
        });
      }
    }
  }

  Future<void> _clearBulkAttendance() async {
    if (_isBulkSaving ||
        _isBulkDeleting ||
        _savingEmployeeIds.isNotEmpty ||
        _deletingEmployeeIds.isNotEmpty) {
      return;
    }

    final date = _formatDate(_selectedDate);
    final recordCount = _savedRecords.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all attendance?'),
        content: Text(
          'Permanently delete all attendance records for '
          '${_displayDate(_selectedDate)}? This may include records for blocked '
          'employees that are not shown in this list. Approximately '
          '$recordCount visible record(s) are currently loaded. This action '
          'cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete all attendance'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isBulkDeleting = true;
    });

    try {
      final deletedCount = await _attendanceApi.deleteBulkAttendance(
        date: date,
        token: widget.token,
      );

      if (!mounted) return;

      await _loadData();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deletedCount attendance record(s) deleted.'),
          backgroundColor: _green,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: _red),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: _red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to clear attendance. Please try again.'),
          backgroundColor: _red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBulkDeleting = false;
        });
      }
    }
  }

  Future<void> _markBulkAttendance() async {
    if (_employees.isEmpty || _isBulkSaving || _isBulkDeleting) return;

    if (_savingEmployeeIds.isNotEmpty || _deletingEmployeeIds.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the current save to finish.'),
        ),
      );
      return;
    }

    final status = await showDialog<AttendanceStatus>(
      context: context,
      builder: (dialogContext) {
        AttendanceStatus selectedStatus = AttendanceStatus.present;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Bulk Attendance'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${_displayDate(_selectedDate)}'),
                  const SizedBox(height: 16),
                  const Text('Apply status to all active employees:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AttendanceStatus>(
                    initialValue: selectedStatus,
                    items: AttendanceStatus.values.map((item) {
                      return DropdownMenuItem<AttendanceStatus>(
                        value: item,
                        child: Text(item.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedStatus = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Existing attendance records for this date may be overwritten.',
                    style: TextStyle(color: _red, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedStatus);
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    if (status == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm bulk attendance'),
        content: Text(
          'Mark ${_employees.length} active employees as '
          '${status.displayName} on ${_displayDate(_selectedDate)}? '
          'Existing records may be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm and save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final requestDate = _formatDate(_selectedDate);

    setState(() {
      _isBulkSaving = true;
    });

    try {
      final saved = await _attendanceApi.markBulkAttendance(
        attendanceDate: requestDate,
        status: status,
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      final employees = await _employeeApi.getEmployees(token: widget.token);

      final records = await _attendanceApi.getMonthlyAttendance(
        year: _selectedDate.year,
        month: _selectedDate.month,
        token: widget.token,
      );

      if (!mounted) return;

      final activeEmployees =
          employees.where((employee) => !employee.blocked).toList()..sort(
            (first, second) =>
                first.name.toLowerCase().compareTo(second.name.toLowerCase()),
          );

      final activeIds = activeEmployees.map((employee) => employee.id).toSet();
      final statuses = <int, AttendanceStatus>{};
      final savedRecords = <int, Attendance>{};

      for (final record in records) {
        if (_isSameDate(record.attendanceDate, _selectedDate) &&
            activeIds.contains(record.employeeId)) {
          savedRecords[record.employeeId] = record;
          statuses[record.employeeId] = record.status;
        }
      }

      setState(() {
        _employees = activeEmployees;
        _selectedStatuses
          ..clear()
          ..addAll(statuses);
        _savedRecords
          ..clear()
          ..addAll(savedRecords);
        _isLoading = false;
        _isBulkSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bulk attendance saved. Server returned ${saved.length} records.',
          ),
          backgroundColor: _green,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isBulkSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: _red),
      );
    } on FormatException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isBulkSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: _red),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isBulkSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The bulk request may have been saved, but refreshing failed. '
            'Refresh the screen to verify the records.',
          ),
          backgroundColor: _red,
        ),
      );
    }
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5EAF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 9),
            Text(
              '$count',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required Employee employee,
    required AttendanceStatus status,
    required Color color,
  }) {
    final selected = _selectedStatuses[employee.id] == status;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ChoiceChip(
          label: Center(
            child: Text(
              status.displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          selected: selected,
          showCheckmark: false,
          selectedColor: color,
          backgroundColor: Colors.white,
          side: BorderSide(color: selected ? color : const Color(0xFFE0E5ED)),
          labelStyle: TextStyle(
            color: selected ? Colors.white : const Color(0xFF344054),
            fontWeight: FontWeight.w600,
          ),
          onSelected:
              _isBulkSaving ||
                  _isBulkDeleting ||
                  _deletingEmployeeIds.contains(employee.id) ||
                  _savingEmployeeIds.contains(employee.id)
              ? null
              : (_) => _selectStatus(employee.id, status),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    final selectedStatus = _selectedStatuses[employee.id];
    final savedRecord = _savedRecords[employee.id];

    final isSaved =
        savedRecord != null &&
        _isSameDate(savedRecord.attendanceDate, _selectedDate) &&
        savedRecord.status == selectedStatus;

    final isSaving = _savingEmployeeIds.contains(employee.id);
    final isDeleting = _deletingEmployeeIds.contains(employee.id);
    final trimmedName = employee.name.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7EBF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFE8EEFF),
                  child: Text(
                    trimmedName.isEmpty ? '?' : trimmedName[0].toUpperCase(),
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        employee.mobile,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSaved)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: _green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Saved',
                        style: TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Attendance status',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusOption(
                  employee: employee,
                  status: AttendanceStatus.present,
                  color: _green,
                ),
                _buildStatusOption(
                  employee: employee,
                  status: AttendanceStatus.absent,
                  color: _red,
                ),
                _buildStatusOption(
                  employee: employee,
                  status: AttendanceStatus.halfDay,
                  color: _orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    selectedStatus == null ||
                        isSaving ||
                        isDeleting ||
                        _isBulkSaving ||
                        _isBulkDeleting
                    ? null
                    : () => _saveAttendance(employee),
                icon: isSaving
                    ? const SizedBox(
                        height: 17,
                        width: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(isSaving ? 'Saving...' : 'Save attendance'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (savedRecord != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      _isBulkSaving ||
                          _isBulkDeleting ||
                          _savingEmployeeIds.isNotEmpty ||
                          _deletingEmployeeIds.isNotEmpty
                      ? null
                      : () => _clearEmployeeAttendance(employee),
                  icon: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(
                    isDeleting ? 'Deleting attendance...' : 'Clear attendance',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red,
                    side: const BorderSide(color: _red),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: _red),
            const SizedBox(height: 16),
            const Text(
              'Could not load attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, height: 1.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 54, color: _primaryBlue),
          const SizedBox(height: 16),
          const Text(
            'No active employees',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add an employee or unblock an existing employee to mark attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _textPrimary,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Track daily employee attendance',
              style: TextStyle(
                fontSize: 12,
                color: _textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh attendance',
            onPressed: _isLoading || _isBulkSaving || _isBulkDeleting
                ? null
                : _loadData,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _isBulkSaving || _isBulkDeleting
                          ? null
                          : _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5EAF2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EEFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_month_outlined,
                                color: _primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Attendance date',
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _displayDate(_selectedDate),
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_calendar_outlined,
                              color: _primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _buildSummaryCard(
                          title: 'Present',
                          count: _presentCount,
                          icon: Icons.check_circle_outline,
                          color: _green,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          title: 'Absent',
                          count: _absentCount,
                          icon: Icons.cancel_outlined,
                          color: _red,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          title: 'Half Day',
                          count: _halfDayCount,
                          icon: Icons.timelapse_outlined,
                          color: _orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5EAF2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: _primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_employees.length} active employees',
                              style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '$_unmarkedCount unmarked',
                            style: TextStyle(
                              color: _unmarkedCount == 0
                                  ? _green
                                  : _textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Employee attendance',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Select a status and save each employee individually, or use bulk attendance.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _employees.isEmpty ||
                                _isBulkSaving ||
                                _isBulkDeleting ||
                                _isLoading
                            ? null
                            : _markBulkAttendance,
                        icon: _isBulkSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.groups_outlined),
                        label: Text(
                          _isBulkSaving
                              ? 'Saving bulk attendance...'
                              : 'Mark all active employees',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isBulkSaving ||
                                _isBulkDeleting ||
                                _savingEmployeeIds.isNotEmpty ||
                                _deletingEmployeeIds.isNotEmpty
                            ? null
                            : _clearBulkAttendance,
                        icon: _isBulkDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_sweep_outlined),
                        label: Text(
                          _isBulkDeleting
                              ? 'Clearing attendance...'
                              : 'Clear all attendance for this date',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _red,
                          side: const BorderSide(color: _red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AttendanceHistoryScreen(token: widget.token),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history_outlined),
                        label: const Text('View attendance history'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryBlue,
                          side: const BorderSide(color: _primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_employees.isEmpty)
                      _buildEmptyState()
                    else
                      ..._employees.map(_buildEmployeeCard),
                  ],
                ),
              ),
      ),
    );
  }
}
