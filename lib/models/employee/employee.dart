import 'dart:convert';

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.mobile,
    required this.initialRate,
    required this.blocked,
    this.createdAt,
  });

  final int id;
  final String name;
  final String mobile;
  final double initialRate;
  final bool blocked;
  final DateTime? createdAt;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: _parseId(json['id']),
      name: _parseString(json['name'], 'name'),
      mobile: _parseString(json['mobile'], 'mobile'),
      initialRate: _parseAmount(json['initialRate']),
      blocked: _parseBool(json['blocked']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'initialRate': initialRate,
      'blocked': blocked,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  Employee copyWith({
    int? id,
    String? name,
    String? mobile,
    double? initialRate,
    bool? blocked,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      initialRate: initialRate ?? this.initialRate,
      blocked: blocked ?? this.blocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const FormatException('Employee ID is missing or invalid.');
  }

  static String _parseString(dynamic value, String field) {
    if (value is String) return value;
    throw FormatException('Employee $field is missing or invalid.');
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const FormatException('Employee initialRate is invalid.');
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return false;
    throw const FormatException('Employee blocked status is invalid.');
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Employee createdAt is invalid.');
    }
    return DateTime.tryParse(value);
  }

  static List<Employee> listFromJson(dynamic json) {
    if (json is! List) {
      throw const FormatException(
        'The server did not return an employee list.',
      );
    }

    return json.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'The server returned an invalid employee record.',
        );
      }
      return Employee.fromJson(item);
    }).toList();
  }

  static Employee fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'The server did not return a valid employee object.',
      );
    }
    return Employee.fromJson(decoded);
  }
}
