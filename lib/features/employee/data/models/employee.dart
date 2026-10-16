class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.mobile,
    required this.initialRate,
    required this.blocked,
    this.createdAt,
    this.joiningDate,
  });

  final int id;
  final String name;
  final String mobile;
  final double initialRate;
  final bool blocked;
  final DateTime? createdAt;
  final DateTime? joiningDate;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      initialRate: _parseDouble(json['initialRate']),
      blocked: json['blocked'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      joiningDate: DateTime.tryParse(json['joiningDate']?.toString() ?? ''),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Formats a date as yyyy-MM-dd for the Spring Boot LocalDate API.
  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'mobile': mobile,
      'initialRate': initialRate,
      'joiningDate': joiningDate == null ? null : _formatDate(joiningDate!),
    };
  }
}
