import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/employee.dart';
import '../../data/repositories/employee_repository.dart';
import 'employee_form_screen.dart';

enum _EmployeeFilter { all, active, blocked }

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final EmployeeRepository _repository = EmployeeRepository(ApiClient());
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Employee>> _employeesFuture;

  String _searchQuery = '';
  _EmployeeFilter _selectedFilter = _EmployeeFilter.all;

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

  void _loadEmployees() {
    _employeesFuture = _repository.getEmployees();
  }

  Future<void> _refresh() async {
    final future = _repository.getEmployees();

    setState(() {
      _employeesFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays refresh errors.
    }
  }

  Future<void> _openForm({Employee? employee}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => EmployeeFormScreen(employee: employee),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      setState(_loadEmployees);
    }
  }

  Future<void> _toggleBlock(Employee employee) async {
    final action = employee.blocked ? 'unblock' : 'block';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${employee.blocked ? 'Unblock' : 'Block'} employee?'),
        content: Text('Do you want to $action ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(employee.blocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repository.toggleBlock(employee.id);

      if (!mounted) return;

      setState(_loadEmployees);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            employee.blocked
                ? '${employee.name} unblocked successfully.'
                : '${employee.name} blocked successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete employee?'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repository.deleteEmployee(employee.id);

      if (!mounted) return;

      setState(_loadEmployees);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  void _showError(Object error) {
    final message = error is ApiException
        ? error.message
        : error is FormatException
        ? error.message
        : 'Something went wrong. Please try again.';

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<Employee> _filterEmployees(List<Employee> employees) {
    final query = _searchQuery.trim().toLowerCase();

    return employees.where((employee) {
      final matchesSearch =
          query.isEmpty ||
          employee.name.toLowerCase().contains(query) ||
          employee.mobile.toLowerCase().contains(query);

      final matchesFilter = switch (_selectedFilter) {
        _EmployeeFilter.all => true,
        _EmployeeFilter.active => !employee.blocked,
        _EmployeeFilter.blocked => employee.blocked,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _changeSearch(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _changeFilter(_EmployeeFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedFilter = _EmployeeFilter.all;
    });
  }

  String _resultText(int count) {
    final filterText = switch (_selectedFilter) {
      _EmployeeFilter.all => 'employees',
      _EmployeeFilter.active => 'active employees',
      _EmployeeFilter.blocked => 'blocked employees',
    };

    if (_searchQuery.trim().isNotEmpty) {
      return '$count matching $filterText';
    }

    return '$count $filterText';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add employee'),
      ),
      body: FutureBuilder<List<Employee>>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && !snapshot.hasData) {
            final error = snapshot.error;

            final message = error is ApiException
                ? error.message
                : 'Unable to load employees.';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        setState(_loadEmployees);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final employees = snapshot.data ?? [];

          final totalEmployees = employees.length;
          final activeEmployees = employees
              .where((employee) => !employee.blocked)
              .length;
          final blockedEmployees = employees
              .where((employee) => employee.blocked)
              .length;

          final filteredEmployees = _filterEmployees(employees);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                // Employee summary cards.
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total',
                        value: totalEmployees,
                        icon: Icons.groups_2_outlined,
                        selected: _selectedFilter == _EmployeeFilter.all,
                        onTap: () => _changeFilter(_EmployeeFilter.all),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Active',
                        value: activeEmployees,
                        icon: Icons.check_circle_outline_rounded,
                        selected: _selectedFilter == _EmployeeFilter.active,
                        onTap: () => _changeFilter(_EmployeeFilter.active),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Blocked',
                        value: blockedEmployees,
                        icon: Icons.block_outlined,
                        selected: _selectedFilter == _EmployeeFilter.blocked,
                        onTap: () => _changeFilter(_EmployeeFilter.blocked),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Search by employee name or mobile number.
                TextField(
                  controller: _searchController,
                  onChanged: _changeSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name or mobile...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: colors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _resultText(filteredEmployees.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_selectedFilter != _EmployeeFilter.all ||
                        _searchQuery.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(
                          Icons.filter_alt_off_outlined,
                          size: 18,
                        ),
                        label: const Text('Clear'),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                if (employees.isEmpty)
                  _EmptyEmployees(onAdd: () => _openForm())
                else if (filteredEmployees.isEmpty)
                  const _NoSearchResults()
                else
                  ...filteredEmployees.map(
                    (employee) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EmployeeCard(
                        employee: employee,
                        onEdit: () => _openForm(employee: employee),
                        onToggleBlock: () => _toggleBlock(employee),
                        onDelete: () => _deleteEmployee(employee),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.4)
                  : colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.primary : colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.employee,
    required this.onEdit,
    required this.onToggleBlock,
    required this.onDelete,
  });

  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onToggleBlock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: employee.blocked
                    ? colors.errorContainer
                    : colors.primaryContainer,
                foregroundColor: employee.blocked
                    ? colors.onErrorContainer
                    : colors.onPrimaryContainer,
                child: Text(
                  employee.name.trim().isEmpty
                      ? '?'
                      : employee.name.trim()[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: employee.blocked
                                ? colors.errorContainer
                                : colors.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            employee.blocked ? 'Blocked' : 'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: employee.blocked
                                  ? colors.onErrorContainer
                                  : colors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            employee.mobile,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.currency_rupee_rounded,
                          size: 15,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rate: ${employee.initialRate.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded, color: colors.outline),
                tooltip: 'Employee actions',
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'toggle':
                      onToggleBlock();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle',
                    child: ListTile(
                      leading: Icon(
                        employee.blocked
                            ? Icons.lock_open_outlined
                            : Icons.block_outlined,
                      ),
                      title: Text(employee.blocked ? 'Unblock' : 'Block'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyEmployees extends StatelessWidget {
  const _EmptyEmployees({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 58,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No employees yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first employee to start managing your workforce.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add employee'),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 54,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'No employees found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another name, mobile number, or employee status.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
