import 'package:flutter/material.dart';

import '../../models/employee/employee.dart';
import '../../services/api_client.dart';
import '../../services/employee/employee_api.dart';
import '../../services/token_storage.dart';
import 'employee_details_screen.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key, required this.token});

  final String token;

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  static const Color _primaryBlue = Color(0xFF2457C5);
  static const Color _pageBackground = Color(0xFFF5F7FB);
  static const Color _activeGreen = Color(0xFF237443);
  static const Color _blockedRed = Color(0xFFB42318);

  final EmployeeApi _employeeApi = EmployeeApi();
  final TokenStorage _tokenStorage = TokenStorage();
  final TextEditingController _searchController = TextEditingController();

  List<Employee> _employees = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  int get _activeCount =>
      _employees.where((employee) => !employee.blocked).length;

  int get _blockedCount =>
      _employees.where((employee) => employee.blocked).length;

  List<Employee> get _filteredEmployees {
    final query = _searchQuery.trim().toLowerCase();

    return _employees.where((employee) {
      final matchesSearch =
          query.isEmpty ||
          employee.name.toLowerCase().contains(query) ||
          employee.mobile.toLowerCase().contains(query);

      final matchesFilter = switch (_selectedFilter) {
        'Active' => !employee.blocked,
        'Blocked' => employee.blocked,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employees = await _employeeApi.getEmployees(token: widget.token);

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _handleExpiredSession();
        return;
      }

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
        _errorMessage = 'Unable to connect to the server. Check your internet and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleExpiredSession() async {
    try {
      await _tokenStorage.deleteToken();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Your session may have expired. Please return to the dashboard and log in again.';
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _errorMessage = 'Your session has expired. Please return to the dashboard and log in again.';
      _isLoading = false;
    });
  }

  Future<void> _refreshEmployees() async {
    await _loadEmployees();
  }

  Future<void> _openEmployeeForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EmployeeFormScreen(token: widget.token),
      ),
    );

    if (created == true && mounted) {
      await _loadEmployees();
    }
  }

  Future<void> _openEmployeeDetails(Employee employee) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EmployeeDetailsScreen(
          token: widget.token,
          employee: employee,
          onEmployeeChanged: (_) {
            if (mounted) {
              _loadEmployees();
            }
          },
        ),
      ),
    );

    if (changed == true && mounted) {
      await _loadEmployees();
    }
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    bool emphasized = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: emphasized ? _primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: emphasized
              ? null
              : Border.all(color: const Color(0xFFE5EAF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: emphasized ? Colors.white : color),
            const SizedBox(height: 10),
            Text(
              count.toString(),
              style: TextStyle(
                color: emphasized ? Colors.white : const Color(0xFF17233B),
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: emphasized ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    final filters = [
      ('All', _employees.length),
      ('Active', _activeCount),
      ('Blocked', _blockedCount),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            ChoiceChip(
              label: Text('${filter.$1} (${filter.$2})'),
              selected: _selectedFilter == filter.$1,
              showCheckmark: false,
              selectedColor: _primaryBlue,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: _selectedFilter == filter.$1
                    ? _primaryBlue
                    : const Color(0xFFE0E5ED),
              ),
              labelStyle: TextStyle(
                color: _selectedFilter == filter.$1
                    ? Colors.white
                    : const Color(0xFF344054),
                fontWeight: _selectedFilter == filter.$1
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontSize: 13,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter.$1;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    final isBlocked = employee.blocked;
    final statusColor = isBlocked ? _blockedRed : _activeGreen;
    final statusBackground = isBlocked
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFE8F5E9);

    final trimmedName = employee.name.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7EBF2)),
      ),
      child: InkWell(
        onTap: () => _openEmployeeDetails(employee),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFE8EEFF),
                child: Text(
                  trimmedName.isEmpty ? '?' : trimmedName[0].toUpperCase(),
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                        color: Color(0xFF17233B),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            employee.mobile,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Initial rate: ${_formatAmount(employee.initialRate)}',
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isBlocked ? 'Blocked' : 'Active',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF98A2B3),
                    size: 21,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFE8EEFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: _primaryBlue),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF17233B),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 18), action],
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
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFFB42318),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load employees',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085), height: 1.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadEmployees,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeContent() {
    final employees = _filteredEmployees;

    if (_employees.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No employees yet',
        description:
            'Add your first employee to start managing your workforce.',
        action: FilledButton.icon(
          onPressed: _openEmployeeForm,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add employee'),
        ),
      );
    }

    if (employees.isEmpty) {
      final isSearching = _searchQuery.trim().isNotEmpty;

      return _buildEmptyState(
        icon: isSearching ? Icons.search_off : Icons.filter_list_off,
        title: isSearching
            ? 'No matching employees'
            : 'No ${_selectedFilter.toLowerCase()} employees',
        description: isSearching
            ? 'Try a different name or mobile number, or clear your search.'
            : 'Choose another status filter to see employees.',
        action: isSearching
            ? OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('Clear search'),
              )
            : TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'All';
                  });
                },
                child: const Text('Show all employees'),
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _searchQuery.trim().isNotEmpty
              ? '${employees.length} search ${employees.length == 1 ? 'result' : 'results'}'
              : '${employees.length} ${_selectedFilter == 'All' ? 'employee' : '${_selectedFilter.toLowerCase()} employee'}${employees.length == 1 ? '' : 's'}',
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...employees.map(_buildEmployeeCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employees',
              style: TextStyle(
                color: Color(0xFF17233B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage your workforce',
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh employees',
            onPressed: _isLoading ? null : _refreshEmployees,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: _employees.isEmpty || _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _openEmployeeForm,
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add employee'),
            ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _refreshEmployees,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                  children: [
                    Row(
                      children: [
                        _buildSummaryCard(
                          label: 'Total',
                          count: _employees.length,
                          icon: Icons.groups_outlined,
                          color: _primaryBlue,
                          emphasized: true,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          label: 'Active',
                          count: _activeCount,
                          icon: Icons.check_circle_outline,
                          color: _activeGreen,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          label: 'Blocked',
                          count: _blockedCount,
                          icon: Icons.block_outlined,
                          color: _blockedRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search name or mobile number',
                        hintStyle: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.close),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5EAF2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5EAF2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _primaryBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusFilters(),
                    const SizedBox(height: 18),
                    _buildEmployeeContent(),
                  ],
                ),
              ),
      ),
    );
  }
}
