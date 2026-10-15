import 'package:flutter/material.dart';

import '../../models/attendance/attendance.dart';
import '../../services/api_client.dart';
import '../../services/attendance/attendance_api.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key, required this.token});

  final String token;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const Color _primaryBlue = Color(0xFF2457C5);
  static const Color _pageBackground = Color(0xFFF5F7FB);
  static const Color _textPrimary = Color(0xFF17233B);
  static const Color _textSecondary = Color(0xFF667085);
  static const Color _green = Color(0xFF237443);
  static const Color _red = Color(0xFFB42318);
  static const Color _orange = Color(0xFFB54708);

  final AttendanceApi _attendanceApi = AttendanceApi();

  DateTime _selectedMonth = DateTime.now();

  List<Attendance> _records = [];
  List<AttendanceSummary> _summaries = [];

  bool _isLoading = true;
  String? _errorMessage;

  int get _presentCount => _records
      .where((record) => record.status == AttendanceStatus.present)
      .length;

  int get _absentCount => _records
      .where((record) => record.status == AttendanceStatus.absent)
      .length;

  int get _halfDayCount => _records
      .where((record) => record.status == AttendanceStatus.halfDay)
      .length;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _attendanceApi.getMonthlyAttendance(
          year: _selectedMonth.year,
          month: _selectedMonth.month,
          token: widget.token,
        ),
        _attendanceApi.getMonthlySummary(
          year: _selectedMonth.year,
          month: _selectedMonth.month,
          token: widget.token,
        ),
      ]);

      if (!mounted) return;

      final records = results[0] as List<Attendance>;
      final summaries = results[1] as List<AttendanceSummary>;

      records.sort((a, b) {
        final dateComparison = b.attendanceDate.compareTo(a.attendanceDate);

        if (dateComparison != 0) {
          return dateComparison;
        }

        final nameA = (a.employeeName ?? '').toLowerCase();
        final nameB = (b.employeeName ?? '').toLowerCase();

        return nameA.compareTo(nameB);
      });

      summaries.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

      setState(() {
        _records = records;
        _summaries = summaries;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load attendance history. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _chooseMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Choose a date in the month',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedMonth = DateTime(selected.year, selected.month);
    });

    await _loadHistory();
  }

  String _monthLabel(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return _green;
      case AttendanceStatus.absent:
        return _red;
      case AttendanceStatus.halfDay:
        return _orange;
    }
  }

  Widget _summaryCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly totals',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _summaryCard('Present', _presentCount, _green),
            const SizedBox(width: 10),
            _summaryCard('Absent', _absentCount, _red),
            const SizedBox(width: 10),
            _summaryCard('Half Day', _halfDayCount, _orange),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'These totals are calculated from the attendance records returned by the server.',
          style: TextStyle(fontSize: 11, color: _textSecondary),
        ),
      ],
    );
  }

  Widget _dailyCount(String label, int count, Color color) {
    return Text(
      '$label: $count',
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDailySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily summary',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (_summaries.isEmpty)
          _emptyCard('No daily summary is available for this month.')
        else
          ..._summaries.map(
            (summary) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateLabel(summary.attendanceDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _dailyCount('Present', summary.present, _green),
                      _dailyCount('Absent', summary.absent, _red),
                      _dailyCount('Half Day', summary.halfDay, _orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Attendance records',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ),
            Text(
              '${_records.length} records',
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_records.isEmpty)
          _emptyCard('No attendance records found for this month.')
        else
          ..._records.map((record) {
            final statusColor = _statusColor(record.status);

            final employeeName = record.employeeName ?? 'Unknown employee';

            final employeeMobile = record.employeeMobile ?? '';

            final reason = record.reason?.trim() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECF3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: _primaryBlue.withValues(alpha: 0.09),
                    child: Text(
                      employeeName.isNotEmpty
                          ? employeeName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: _primaryBlue,
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
                          employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_dateLabel(record.attendanceDate)}'
                          '${employeeMobile.isNotEmpty ? ' • $employeeMobile' : ''}',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (reason.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Reason: $reason',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      record.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _textSecondary, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: InkWell(
                onTap: _chooseMonth,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _pageBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECF3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: _primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected month',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _monthLabel(_selectedMonth),
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
                        Icons.keyboard_arrow_down,
                        color: _textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primaryBlue),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 44,
                              color: _red,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _textPrimary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadHistory,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildMonthlySummary(),
                          const SizedBox(height: 24),
                          _buildDailySummary(),
                          const SizedBox(height: 24),
                          _buildRecords(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
