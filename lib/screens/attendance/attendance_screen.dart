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

  final Map<int, Map<int, Attendance>> _monthlyAttendance = {};
  final Set<int> _savingEmployeeIds = {};

  bool _isLoading = true;
  bool _isBulkSaving = false;
  bool _isBulkDeleting = false;
  final Set<int> _deletingEmployeeIds = {};
  String? _errorMessage;

  int get _presentCount => _savedRecords.values
      .where((record) => record.status == AttendanceStatus.present)
      .length;

  int get _absentCount => _savedRecords.values
      .where((record) => record.status == AttendanceStatus.absent)
      .length;

  int get _halfDayCount => _savedRecords.values
      .where((record) => record.status == AttendanceStatus.halfDay)
      .length;

  int get _unmarkedCount => _employees.length - _savedRecords.length;

  int get _daysInSelectedMonth =>
      DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

  DateTime _dateForDay(int day) =>
      DateTime(_selectedDate.year, _selectedDate.month, day);

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
      final monthlyRecords = <int, Map<int, Attendance>>{};

      for (final record in records) {
        if (!activeEmployeeIds.contains(record.employeeId)) continue;

        monthlyRecords.putIfAbsent(record.employeeId, () => {});
        monthlyRecords[record.employeeId]![record.attendanceDate.day] = record;

        if (_isSameDate(record.attendanceDate, _selectedDate)) {
          savedRecords[record.employeeId] = record;
          statuses[record.employeeId] = record.status;
        }
      }

      setState(() {
        _employees = activeEmployees;
        _monthlyAttendance
          ..clear()
          ..addAll(monthlyRecords);
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
      final monthlyRecords = <int, Map<int, Attendance>>{};

      for (final record in records) {
        if (!activeIds.contains(record.employeeId)) continue;
        monthlyRecords.putIfAbsent(record.employeeId, () => {});
        monthlyRecords[record.employeeId]![record.attendanceDate.day] = record;
        if (_isSameDate(record.attendanceDate, _selectedDate)) {
          savedRecords[record.employeeId] = record;
          statuses[record.employeeId] = record.status;
        }
      }

      setState(() {
        _employees = activeEmployees;
        _monthlyAttendance
          ..clear()
          ..addAll(monthlyRecords);
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EAF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 7),
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

  void _selectRegisterDay(int day) {
    final date = _dateForDay(day);
    final recordsForDay = <int, Attendance>{};
    final statusesForDay = <int, AttendanceStatus>{};

    for (final employee in _employees) {
      final record = _monthlyAttendance[employee.id]?[day];
      if (record != null) {
        recordsForDay[employee.id] = record;
        statusesForDay[employee.id] = record.status;
      }
    }

    setState(() {
      _selectedDate = date;
      _savedRecords
        ..clear()
        ..addAll(recordsForDay);
      _selectedStatuses
        ..clear()
        ..addAll(statusesForDay);
    });
  }

  Future<void> _editMonthlyCell(Employee employee, int day) async {
    if (_isBulkSaving ||
        _isBulkDeleting ||
        _savingEmployeeIds.contains(employee.id) ||
        _deletingEmployeeIds.contains(employee.id)) {
      return;
    }

    final date = _dateForDay(day);
    final existingRecord = _monthlyAttendance[employee.id]?[day];
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(employee.name.trim()),
        content: Text(
          '${_displayDate(date)}\nChoose the attendance status for this day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'PRESENT'),
            child: const Text('Present'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'ABSENT'),
            child: const Text('Absent'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'HALF_DAY'),
            child: const Text('Half day'),
          ),
          if (existingRecord != null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'DELETE'),
              child: const Text('Delete', style: TextStyle(color: _red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'DELETE') {
      await _deleteMonthlyCell(employee, date, existingRecord!);
      return;
    }

    final status = switch (choice) {
      'PRESENT' => AttendanceStatus.present,
      'ABSENT' => AttendanceStatus.absent,
      'HALF_DAY' => AttendanceStatus.halfDay,
      _ => null,
    };
    if (status == null) return;

    setState(() => _savingEmployeeIds.add(employee.id));
    try {
      final record = await _attendanceApi.markAttendance(
        employeeId: employee.id,
        attendanceDate: _formatDate(date),
        status: status,
        token: widget.token,
      );
      if (!mounted) return;

      setState(() {
        _selectedDate = date;
        _monthlyAttendance.putIfAbsent(employee.id, () => {})[day] = record;
      });

      _selectRegisterDay(day);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${employee.name}: ${status.displayName} saved for ${_displayDate(date)}.',
          ),
          backgroundColor: _green,
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: _red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save attendance. Please try again.'),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingEmployeeIds.remove(employee.id));
    }
  }

  Future<void> _deleteMonthlyCell(
    Employee employee,
    DateTime date,
    Attendance record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete attendance?'),
        content: Text(
          'Permanently delete ${employee.name}\'s attendance for ${_displayDate(date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingEmployeeIds.add(employee.id));
    try {
      await _attendanceApi.deleteAttendance(
        attendanceId: record.id,
        token: widget.token,
      );
      if (!mounted) return;

      setState(() {
        _monthlyAttendance[employee.id]?.remove(date.day);
        if (_isSameDate(date, _selectedDate)) {
          _savedRecords.remove(employee.id);
          _selectedStatuses.remove(employee.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${employee.name}\'s attendance deleted for ${_displayDate(date)}.',
          ),
          backgroundColor: _green,
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: _red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete attendance. Please try again.'),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingEmployeeIds.remove(employee.id));
    }
  }

  Widget _buildMonthDayHeader(int day) {
    final date = _dateForDay(day);
    final isSelected = _isSameDate(date, _selectedDate);
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return InkWell(
      onTap: () => _selectRegisterDay(day),
      child: Container(
        width: 42,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCE7FF) : const Color(0xFFF0F3F8),
          border: const Border(
            right: BorderSide(color: Color(0xFFDCE3ED), width: 0.7),
            bottom: BorderSide(color: Color(0xFFDCE3ED), width: 0.8),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isSelected ? _primaryBlue : _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              weekdays[date.weekday - 1],
              style: TextStyle(
                color: isSelected ? _primaryBlue : _textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCell(Employee employee, int day, int rowIndex) {
    final record = _monthlyAttendance[employee.id]?[day];
    final status = record?.status;
    final isSelectedDate = _isSameDate(_dateForDay(day), _selectedDate);
    final isBusy =
        _savingEmployeeIds.contains(employee.id) ||
        _deletingEmployeeIds.contains(employee.id) ||
        _isBulkSaving ||
        _isBulkDeleting;

    Color statusColor;
    String label;
    switch (status) {
      case AttendanceStatus.present:
        statusColor = _green;
        label = 'P';
        break;
      case AttendanceStatus.absent:
        statusColor = _red;
        label = 'A';
        break;
      case AttendanceStatus.halfDay:
        statusColor = _orange;
        label = 'H';
        break;
      case null:
        statusColor = _textSecondary;
        label = '–';
        break;
    }

    return InkWell(
      onTap: isBusy ? null : () => _editMonthlyCell(employee, day),
      child: Container(
        width: 42,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelectedDate
              ? const Color(0xFFF0F5FF)
              : rowIndex.isEven
              ? Colors.white
              : const Color(0xFFFAFBFD),
          border: const Border(
            right: BorderSide(color: Color(0xFFDCE3ED), width: 0.7),
            bottom: BorderSide(color: Color(0xFFDCE3ED), width: 0.8),
          ),
        ),
        child: Container(
          width: 25,
          height: 27,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: status == null
                ? Colors.transparent
                : statusColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyRegister() {
    const employeeColumnWidth = 148.0;
    final monthLabel =
        '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3ED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            color: const Color(0xFFE8EEFF),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'MONTHLY ATTENDANCE REGISTER',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: employeeColumnWidth,
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F3F8),
                        border: Border(
                          right: BorderSide(
                            color: Color(0xFFDCE3ED),
                            width: 0.8,
                          ),
                          bottom: BorderSide(
                            color: Color(0xFFDCE3ED),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: const Text(
                        'EMPLOYEE',
                        style: TextStyle(
                          color: Color(0xFF475467),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._employees.asMap().entries.map((entry) {
                      final employee = entry.value;
                      return Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: entry.key.isEven
                              ? Colors.white
                              : const Color(0xFFFAFBFD),
                          border: const Border(
                            right: BorderSide(
                              color: Color(0xFFDCE3ED),
                              width: 0.8,
                            ),
                            bottom: BorderSide(
                              color: Color(0xFFDCE3ED),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.key + 1}. ${employee.mobile}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          _daysInSelectedMonth,
                          (index) => _buildMonthDayHeader(index + 1),
                        ),
                      ),
                      ..._employees.asMap().entries.map(
                        (entry) => Row(
                          children: List.generate(
                            _daysInSelectedMonth,
                            (dayIndex) => _buildMonthCell(
                              entry.value,
                              dayIndex + 1,
                              entry.key,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            color: const Color(0xFFFAFBFD),
            child: const Text(
              'Tap a date at the top to select it. Tap any cell to mark or edit attendance.',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ],
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
            const SizedBox(height: 12),
            const Text(
              'Could not load attendance',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
              ),
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
        title: const Text(
          'Attendance Register',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
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
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _isBulkSaving || _isBulkDeleting
                            ? null
                            : _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDCE3ED)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: _primaryBlue,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DATE OF ATTENDANCE',
                                      style: TextStyle(
                                        color: _textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _displayDate(_selectedDate),
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.edit_calendar_outlined,
                                color: _primaryBlue,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildSummaryCard(
                          title: 'Present',
                          count: _presentCount,
                          icon: Icons.check_circle_outline,
                          color: _green,
                        ),
                        const SizedBox(width: 6),
                        _buildSummaryCard(
                          title: 'Absent',
                          count: _absentCount,
                          icon: Icons.cancel_outlined,
                          color: _red,
                        ),
                        const SizedBox(width: 6),
                        _buildSummaryCard(
                          title: 'Half day',
                          count: _halfDayCount,
                          icon: Icons.timelapse_outlined,
                          color: _orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFDCE3ED)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: _textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '${_employees.length} employees',
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'Marked ${_savedRecords.length}/${_employees.length}',
                            style: TextStyle(
                              color: _unmarkedCount == 0
                                  ? _green
                                  : _textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
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
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.groups_outlined, size: 18),
                            label: Text(
                              _isBulkSaving ? 'Saving...' : 'Mark all',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 11,
                                horizontal: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _savedRecords.isEmpty ||
                                    _isBulkSaving ||
                                    _isBulkDeleting ||
                                    _savingEmployeeIds.isNotEmpty ||
                                    _deletingEmployeeIds.isNotEmpty
                                ? null
                                : _clearBulkAttendance,
                            icon: _isBulkDeleting
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_sweep_outlined,
                                    size: 18,
                                  ),
                            label: Text(
                              _isBulkDeleting ? 'Clearing...' : 'Clear date',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _red,
                              side: const BorderSide(color: Color(0xFFE2B8B5)),
                              padding: const EdgeInsets.symmetric(
                                vertical: 11,
                                horizontal: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AttendanceHistoryScreen(token: widget.token),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history, size: 17),
                        label: const Text('View history'),
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (_employees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: _buildEmptyState(),
                      )
                    else
                      _buildMonthlyRegister(),
                    const SizedBox(height: 9),
                    const Text(
                      'P = Present    A = Absent    H = Half day    – = Not marked',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
