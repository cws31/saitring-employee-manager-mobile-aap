import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../employee/data/models/employee.dart';
import '../../../employee/data/repositories/employee_repository.dart';
import '../../data/models/attendance.dart';
import '../../data/models/attendance_summary.dart';
import '../../data/repositories/attendance_repository.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  late final ApiClient _apiClient;
  late final EmployeeRepository _employeeRepository;
  late final AttendanceRepository _attendanceRepository;
  late final TextEditingController _searchController;

  late DateTime _month;

  List<Employee> _employees = [];
  List<Attendance> _records = [];
  List<AttendanceSummary> _monthlySummaries = [];

  bool _loading = true;
  bool _syncingScroll = false;
  bool _loadingSummaries = false;

  final Set<String> _savingCells = {};
  String? _errorMessage;

  static const double _nameWidth = 148;
  static const double _cellWidth = 44;
  static const double _rowHeight = 54;

  final List<ScrollController> _horizontalControllers = [];

  int get _daysInMonth => DateUtils.getDaysInMonth(_month.year, _month.month);

  List<Employee> get _visibleEmployees {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return _employees;

    return _employees.where((employee) {
      return employee.name.toLowerCase().contains(query) ||
          employee.mobile.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _month = DateTime(now.year, now.month);

    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);

    _apiClient = ApiClient();
    _employeeRepository = EmployeeRepository(_apiClient);
    _attendanceRepository = AttendanceRepository(_apiClient);

    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    for (final controller in _horizontalControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;

    _resetHorizontalControllers(_visibleEmployees.length);
    setState(() {});
  }

  void _resetHorizontalControllers(int rowCount) {
    for (final controller in _horizontalControllers) {
      controller.dispose();
    }

    _horizontalControllers.clear();

    for (var i = 0; i <= rowCount; i++) {
      final controller = ScrollController();
      controller.addListener(() => _synchronizeScroll(controller));
      _horizontalControllers.add(controller);
    }
  }

  void _synchronizeScroll(ScrollController source) {
    if (_syncingScroll || !source.hasClients) return;

    _syncingScroll = true;

    try {
      final offset = source.offset;

      for (final controller in _horizontalControllers) {
        if (controller == source || !controller.hasClients) continue;

        final position = controller.position;
        final target = offset.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );

        if ((position.pixels - target).abs() > 0.5) {
          controller.jumpTo(target.toDouble());
        }
      }
    } finally {
      _syncingScroll = false;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _employeeRepository.getEmployees(),
        _attendanceRepository.getMonthlyAttendance(
          year: _month.year,
          month: _month.month,
        ),
        _attendanceRepository.getMonthlySummary(
          year: _month.year,
          month: _month.month,
        ),
      ]);

      if (!mounted) return;

      final allEmployees = results[0] as List<Employee>;

      // Temporary debugging: inspect actual joining dates returned by the API.
      for (final employee in allEmployees) {
        debugPrint(
          'ATTENDANCE DEBUG: '
          'name=${employee.name}, '
          'joiningDate=${employee.joiningDate}, '
          'selectedMonth=${_month.year}-${_month.month}, '
          'blocked=${employee.blocked}',
        );
      }

      final selectedMonth = DateTime(_month.year, _month.month);

      _employees =
          allEmployees.where((employee) {
            final joiningDate = employee.joiningDate;

            // Hide blocked employees and employees without a joining date.
            if (employee.blocked || joiningDate == null) {
              return false;
            }

            // Compare months, not individual days.
            final employeeJoiningMonth = DateTime(
              joiningDate.year,
              joiningDate.month,
            );

            return !employeeJoiningMonth.isAfter(selectedMonth);
          }).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

      _records = results[1] as List<Attendance>;
      _monthlySummaries = results[2] as List<AttendanceSummary>;

      _resetHorizontalControllers(_visibleEmployees.length);

      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = _errorText(error);
      });
    }
  }

  String _errorText(Object error) {
    if (error is ApiException) return error.message;
    if (error is FormatException) return error.message;

    return 'Unable to load attendance. Please try again.';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Attendance? _recordFor(int employeeId, int day) {
    for (final record in _records) {
      if (record.employeeId == employeeId &&
          record.attendanceDate.year == _month.year &&
          record.attendanceDate.month == _month.month &&
          record.attendanceDate.day == day) {
        return record;
      }
    }

    return null;
  }

  String get _monthName =>
      MaterialLocalizations.of(context).formatMonthYear(_month);

  String _dateText(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  Future<void> _selectMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Choose a date in the required month',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _month = DateTime(selected.year, selected.month);
    });

    await _loadData();
  }

  Future<void> _moveMonth(int difference) async {
    if (_loading) return;

    setState(() {
      _month = DateTime(_month.year, _month.month + difference);
    });

    await _loadData();
  }

  Future<void> _changeAttendance(Employee employee, int day) async {
    final date = DateTime(_month.year, _month.month, day);
    final existing = _recordFor(employee.id, day);
    final key = '${employee.id}-$day';

    if (_loading || _savingCells.contains(key)) return;

    final selection = await showDialog<_AttendanceChoice>(
      context: context,
      builder: (dialogContext) => _AttendanceChoiceDialog(
        employeeName: employee.name,
        date: date,
        initialStatus: existing?.status,
        initialNote: existing?.reason ?? '',
        canDelete: existing != null,
      ),
    );

    if (selection == null || !mounted) return;

    if (selection.delete) {
      if (existing != null) {
        await _deleteOneRecord(existing);
      }
      return;
    }

    final selectedStatus = selection.status;
    if (selectedStatus == null) return;

    setState(() => _savingCells.add(key));

    try {
      await _attendanceRepository.markAttendance(
        employeeId: employee.id,
        attendanceDate: date,
        status: selectedStatus,
        reason: selection.note.trim().isEmpty ? null : selection.note.trim(),
      );

      _showMessage('${employee.name}: ${selectedStatus.label} saved.');
      await _loadData();
    } catch (error) {
      _showMessage(_errorText(error));
    } finally {
      if (mounted) {
        setState(() => _savingCells.remove(key));
      }
    }
  }

  Future<String?> _askReason({
    required String title,
    required String description,
  }) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 255,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reason (if required)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteOneRecord(Attendance record) async {
    final confirmed = await _confirmDelete(
      title: 'Delete attendance?',
      message:
          'Permanently delete this attendance record for '
          '${record.employeeName.isEmpty ? 'employee #${record.employeeId}' : record.employeeName} '
          'on ${_dateText(record.attendanceDate)}?',
    );

    if (!confirmed || !mounted) return;

    final reason = await _askReason(
      title: 'Deletion reason',
      description: 'Enter a reason if required by your backend.',
    );

    if (reason == null) return;

    try {
      await _attendanceRepository.deleteAttendance(
        attendanceId: record.id,
        reason: reason.isEmpty ? null : reason,
      );

      _showMessage('Attendance record deleted.');
      await _loadData();
    } catch (error) {
      _showMessage(_errorText(error));
    }
  }

  Future<void> _deleteEmployeeForDate() async {
    if (_employees.isEmpty) {
      _showMessage('No active employees available.');
      return;
    }

    final employee = await showDialog<Employee>(
      context: context,
      builder: (dialogContext) {
        Employee selected = _employees.first;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Select employee'),
            content: DropdownButtonFormField<Employee>(
              initialValue: selected,
              isExpanded: true,
              items: _employees
                  .map(
                    (employee) => DropdownMenuItem<Employee>(
                      value: employee,
                      child: Text(employee.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setDialogState(() => selected = value);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, selected),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );

    if (employee == null || !mounted) return;

    final date = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final confirmed = await _confirmDelete(
      title: 'Delete employee attendance?',
      message: 'Delete ${employee.name}\'s attendance for ${_dateText(date)}?',
    );

    if (!confirmed || !mounted) return;

    final reason = await _askReason(
      title: 'Deletion reason',
      description: 'Enter a reason if required by your backend.',
    );

    if (reason == null) return;

    try {
      await _attendanceRepository.deleteEmployeeAttendance(
        employeeId: employee.id,
        date: date,
        reason: reason.isEmpty ? null : reason,
      );

      _showMessage('Employee attendance deletion completed.');
      await _loadData();
    } catch (error) {
      _showMessage(_errorText(error));
    }
  }

  Future<void> _deleteAllForDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final confirmed = await _confirmDelete(
      title: 'Delete all attendance for this date?',
      message:
          'This permanently deletes attendance records for ${_dateText(date)}. '
          'This action may affect every employee covered by the backend endpoint.',
    );

    if (!confirmed || !mounted) return;

    final reason = await _askReason(
      title: 'Deletion reason',
      description: 'Enter a reason if required by your backend.',
    );

    if (reason == null) return;

    try {
      await _attendanceRepository.deleteBulkAttendance(
        date: date,
        reason: reason.isEmpty ? null : reason,
      );

      _showMessage('Attendance deletion completed for ${_dateText(date)}.');
      await _loadData();
    } catch (error) {
      _showMessage(_errorText(error));
    }
  }

  Future<void> _bulkMarkAttendance() async {
    if (_employees.isEmpty) {
      _showMessage('No active employees available.');
      return;
    }

    final choice = await showDialog<_BulkAttendanceChoice>(
      context: context,
      builder: (dialogContext) => _BulkAttendanceDialog(initialDate: _month),
    );

    if (choice == null || !mounted) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirm bulk attendance'),
            content: Text(
              'Submit ${choice.status.label.toLowerCase()} attendance for '
              '${_dateText(choice.date)} using the backend bulk endpoint? '
              'The backend determines which employees are affected.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    try {
      final saved = await _attendanceRepository.markBulkAttendance(
        attendanceDate: choice.date,
        status: choice.status,
        reason: choice.note.trim().isEmpty ? null : choice.note.trim(),
      );

      _showMessage(
        'Bulk attendance submitted. ${saved.length} records returned.',
      );
      await _loadData();
    } catch (error) {
      _showMessage(_errorText(error));
    }
  }

  Future<void> _showDailySummary() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    try {
      final summary = await _attendanceRepository.getDailySummary(date: date);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Daily summary · ${_dateText(summary.attendanceDate)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _summaryLine('Present', summary.present, Colors.green),
              _summaryLine(
                'Absent',
                summary.absent,
                Theme.of(context).colorScheme.error,
              ),
              _summaryLine('Half day', summary.halfPresent, Colors.orange),
              const Divider(),
              _summaryLine(
                'Total records',
                summary.total,
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      _showMessage(_errorText(error));
    }
  }

  Future<void> _showMonthlySummaries() async {
    setState(() => _loadingSummaries = true);

    try {
      final summaries = await _attendanceRepository.getMonthlySummary(
        year: _month.year,
        month: _month.month,
      );

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Daily summaries · $_monthName',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: summaries.isEmpty
                      ? const Center(
                          child: Text('No summary records returned.'),
                        )
                      : ListView.separated(
                          itemCount: summaries.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final summary = summaries[index];

                            return ListTile(
                              title: Text(_dateText(summary.attendanceDate)),
                              subtitle: Text(
                                'Present: ${summary.present} · '
                                'Absent: ${summary.absent} · '
                                'Half day: ${summary.halfPresent}',
                              ),
                              trailing: Text(
                                'Total ${summary.total}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _loadingSummaries = false);
    }
  }

  Future<void> _showEmployeeHistory(Employee employee) async {
    try {
      final records = await _attendanceRepository.getEmployeeMonthlyAttendance(
        employeeId: employee.id,
        year: _month.year,
        month: _month.month,
      );

      if (!mounted) return;

      final present = records
          .where((r) => r.status.apiValue == 'PRESENT')
          .length;
      final absent = records.where((r) => r.status.apiValue == 'ABSENT').length;
      final half = records.where((r) => r.status.apiValue == 'HALF_DAY').length;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      Text(_monthName),
                      const SizedBox(height: 8),
                      Text(
                        'Present: $present · Absent: $absent · Half day: $half',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: records.isEmpty
                      ? const Center(
                          child: Text('No attendance records this month.'),
                        )
                      : ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final record = records[index];

                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(switch (record.status.apiValue) {
                                  'PRESENT' => 'P',
                                  'ABSENT' => 'A',
                                  _ => 'H',
                                }),
                              ),
                              title: Text(_dateText(record.attendanceDate)),
                              subtitle: Text(
                                record.reason?.isNotEmpty == true
                                    ? record.reason!
                                    : record.status.label,
                              ),
                              trailing: IconButton(
                                tooltip: 'Delete record',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  Navigator.pop(sheetContext);
                                  await _deleteOneRecord(record);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      _showMessage(_errorText(error));
    }
  }

  Widget _summaryLine(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Register'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Attendance actions',
            onSelected: (value) {
              switch (value) {
                case 'bulk':
                  _bulkMarkAttendance();
                case 'daily':
                  _showDailySummary();
                case 'monthly':
                  _showMonthlySummaries();
                case 'delete_employee':
                  _deleteEmployeeForDate();
                case 'delete_date':
                  _deleteAllForDate();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk',
                child: ListTile(
                  leading: Icon(Icons.done_all),
                  title: Text('Bulk mark attendance'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'daily',
                child: ListTile(
                  leading: Icon(Icons.today_outlined),
                  title: Text('Daily summary'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'monthly',
                child: ListTile(
                  leading: Icon(Icons.calendar_view_month),
                  title: Text('Monthly daily summaries'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete_employee',
                child: ListTile(
                  leading: Icon(Icons.person_remove_outlined),
                  title: Text('Delete employee attendance'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete_date',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep_outlined),
                  title: Text('Delete all for a date'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Refresh register',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                children: [
                  _buildMonthSelector(colors),
                  const SizedBox(height: 12),
                  _buildMonthlySummary(colors),
                  const SizedBox(height: 16),
                  _buildSearch(colors),
                  const SizedBox(height: 12),
                  _buildRegister(colors),
                  const SizedBox(height: 12),
                  _buildLegend(colors),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load attendance.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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

  Widget _buildMonthSelector(ColorScheme colors) {
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthName,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Monthly register',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => _moveMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Choose month',
              onPressed: _selectMonth,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => _moveMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary(ColorScheme colors) {
    final present = _monthlySummaries.fold<int>(
      0,
      (sum, item) => sum + item.present,
    );
    final absent = _monthlySummaries.fold<int>(
      0,
      (sum, item) => sum + item.absent,
    );
    final halfDay = _monthlySummaries.fold<int>(
      0,
      (sum, item) => sum + item.halfPresent,
    );

    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            'Present',
            present,
            Colors.green.shade700,
            colors,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(child: _summaryTile('Absent', absent, colors.error, colors)),
        const SizedBox(width: 7),
        Expanded(
          child: _summaryTile(
            'Half day',
            halfDay,
            Colors.orange.shade800,
            colors,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile(
    String label,
    int count,
    Color color,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildSearch(ColorScheme colors) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search employee name or mobile',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );
  }

  Widget _buildRegister(ColorScheme colors) {
    final employees = _visibleEmployees;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Register',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${employees.length} employees',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_loadingSummaries) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
          if (employees.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  _employees.isEmpty
                      ? 'No active employees found.'
                      : 'No employees match your search.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Row(
              children: [
                _buildEmployeeHeader(colors),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: SingleChildScrollView(
                      controller: _horizontalControllers[0],
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          _daysInMonth,
                          (index) => _dateHeader(index + 1, colors),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (employees.isNotEmpty)
            ...List.generate(
              employees.length,
              (index) => _employeeRow(employees[index], index + 1, colors),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeHeader(ColorScheme colors) {
    return Container(
      width: _nameWidth,
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        border: Border(
          right: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Text(
        'EMPLOYEE',
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _dateHeader(int day, ColorScheme colors) {
    final date = DateTime(_month.year, _month.month, day);
    final weekend = date.weekday == DateTime.sunday;
    final today = DateUtils.isSameDay(date, DateTime.now());

    return Container(
      width: _cellWidth,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: today
            ? colors.primaryContainer
            : weekend
            ? colors.surfaceContainerHighest
            : colors.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: today
                  ? colors.onPrimaryContainer
                  : weekend
                  ? colors.error
                  : colors.onSurface,
            ),
          ),
          Text(
            _weekdayLetter(date.weekday),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }

  String _weekdayLetter(int weekday) =>
      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];

  Widget _employeeRow(
    Employee employee,
    int controllerIndex,
    ColorScheme colors,
  ) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          InkWell(
            onTap: () => _showEmployeeHistory(employee),
            child: Container(
              width: _nameWidth,
              height: _rowHeight,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  right: BorderSide(color: colors.outlineVariant),
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    employee.mobile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalControllers[controllerIndex],
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _daysInMonth,
                  (index) => _attendanceCell(employee, index + 1, colors),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceCell(Employee employee, int day, ColorScheme colors) {
    final date = DateTime(_month.year, _month.month, day);
    final record = _recordFor(employee.id, day);
    final status = record?.status;
    final key = '${employee.id}-$day';
    final saving = _savingCells.contains(key);
    final today = DateUtils.isSameDay(date, DateTime.now());

    final joiningDate = employee.joiningDate;
    final beforeJoining =
        joiningDate == null ||
        date.isBefore(
          DateTime(joiningDate.year, joiningDate.month, joiningDate.day),
        );

    final Color foreground;
    final Color background;

    if (beforeJoining) {
      foreground = colors.onSurfaceVariant.withValues(alpha: 0.45);
      background = colors.surfaceContainerLow;
    } else {
      switch (status?.apiValue) {
        case 'PRESENT':
          foreground = Colors.green.shade800;
          background = Colors.green.withValues(alpha: 0.12);
          break;
        case 'ABSENT':
          foreground = colors.error;
          background = colors.error.withValues(alpha: 0.10);
          break;
        case 'HALF_DAY':
          foreground = Colors.orange.shade900;
          background = Colors.orange.withValues(alpha: 0.13);
          break;
        default:
          foreground = colors.onSurfaceVariant;
          background = today
              ? colors.primaryContainer.withValues(alpha: 0.35)
              : colors.surface;
      }
    }

    return InkWell(
      onTap: saving || beforeJoining
          ? null
          : () => _changeAttendance(employee, day),
      child: Container(
        width: _cellWidth,
        height: _rowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          border: Border(
            right: BorderSide(color: colors.outlineVariant),
            bottom: BorderSide(color: colors.outlineVariant),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                beforeJoining
                    ? '—'
                    : switch (status?.apiValue) {
                        'PRESENT' => 'P',
                        'ABSENT' => 'A',
                        'HALF_DAY' => 'H',
                        _ => '—',
                      },
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLegend(ColorScheme colors) {
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 14,
          runSpacing: 10,
          children: [
            _legendItem('P', 'Present', Colors.green.shade800),
            _legendItem('A', 'Absent', colors.error),
            _legendItem('H', 'Half day', Colors.orange.shade900),
            _legendItem('—', 'Not marked', colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String symbol, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            symbol,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AttendanceChoice {
  const _AttendanceChoice({this.status, this.note = '', this.delete = false});

  final AttendanceStatus? status;
  final String note;
  final bool delete;
}

class _AttendanceChoiceDialog extends StatefulWidget {
  const _AttendanceChoiceDialog({
    required this.employeeName,
    required this.date,
    required this.initialStatus,
    required this.initialNote,
    required this.canDelete,
  });

  final String employeeName;
  final DateTime date;
  final AttendanceStatus? initialStatus;
  final String initialNote;
  final bool canDelete;

  @override
  State<_AttendanceChoiceDialog> createState() =>
      _AttendanceChoiceDialogState();
}

class _AttendanceChoiceDialogState extends State<_AttendanceChoiceDialog> {
  late AttendanceStatus _status;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus ?? AttendanceStatus.present;
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${widget.date.day.toString().padLeft(2, '0')}/'
        '${widget.date.month.toString().padLeft(2, '0')}/'
        '${widget.date.year}';

    return AlertDialog(
      title: Text(
        widget.initialStatus == null ? 'Mark attendance' : 'Edit attendance',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.employeeName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(dateText),
            const SizedBox(height: 16),
            RadioGroup<AttendanceStatus>(
              groupValue: _status,
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
              child: Column(
                children: AttendanceStatus.values
                    .map(
                      (status) => RadioListTile<AttendanceStatus>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(status.label),
                        value: status,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLength: 255,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reason / note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.canDelete)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _AttendanceChoice(delete: true)),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _AttendanceChoice(
              status: _status,
              note: _noteController.text.trim(),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _BulkAttendanceChoice {
  const _BulkAttendanceChoice({
    required this.date,
    required this.status,
    required this.note,
  });

  final DateTime date;
  final AttendanceStatus status;
  final String note;
}

class _BulkAttendanceDialog extends StatefulWidget {
  const _BulkAttendanceDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_BulkAttendanceDialog> createState() => _BulkAttendanceDialogState();
}

class _BulkAttendanceDialogState extends State<_BulkAttendanceDialog> {
  late DateTime _date;
  AttendanceStatus _status = AttendanceStatus.present;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_date.day.toString().padLeft(2, '0')}/'
        '${_date.month.toString().padLeft(2, '0')}/'
        '${_date.year}';

    return AlertDialog(
      title: const Text('Bulk mark attendance'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The backend determines which employees are affected by bulk marking.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(dateText),
            ),
            const SizedBox(height: 8),
            RadioGroup<AttendanceStatus>(
              groupValue: _status,
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
              child: Column(
                children: AttendanceStatus.values
                    .map(
                      (status) => RadioListTile<AttendanceStatus>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(status.label),
                        value: status,
                      ),
                    )
                    .toList(),
              ),
            ),
            TextField(
              controller: _noteController,
              maxLength: 255,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason / note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _BulkAttendanceChoice(
              date: _date,
              status: _status,
              note: _noteController.text.trim(),
            ),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
