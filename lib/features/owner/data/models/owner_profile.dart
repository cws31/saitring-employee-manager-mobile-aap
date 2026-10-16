class OwnerProfile {
  const OwnerProfile({
    required this.id,
    required this.ownerName,
    required this.organizationName,
    required this.email,
    required this.mobileNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.website,
    required this.logoExists,
    this.logoVersion,
  });

  final int id;
  final String ownerName;
  final String organizationName;
  final String email;
  final String mobileNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? website;
  final bool logoExists;
  final String? logoVersion;

  factory OwnerProfile.fromJson(Map<String, dynamic> json) {
    return OwnerProfile(
      id: (json['id'] as num).toInt(),
      ownerName: json['ownerName']?.toString() ?? '',
      organizationName: json['organizationName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString(),
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      postalCode: json['postalCode']?.toString(),
      website: json['website']?.toString(),
      logoExists: json['logoExists'] == true,
      logoVersion: json['logoVersion']?.toString(),
    );
  }
}
