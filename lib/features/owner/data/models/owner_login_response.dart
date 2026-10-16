class OwnerLoginResponse {
  const OwnerLoginResponse({
    required this.otpRequired,
    required this.message,
    this.token,
    this.tokenType,
    this.ownerId,
    this.ownerName,
    this.organizationName,
    this.email,
    this.mobileNumber,
    this.logoUrl,
  });

  final bool otpRequired;
  final String message;
  final String? token;
  final String? tokenType;
  final int? ownerId;
  final String? ownerName;
  final String? organizationName;
  final String? email;
  final String? mobileNumber;
  final String? logoUrl;

  factory OwnerLoginResponse.fromJson(Map<String, dynamic> json) {
    return OwnerLoginResponse(
      otpRequired: json['otpRequired'] == true,
      message: json['message']?.toString() ?? '',
      token: json['token']?.toString(),
      tokenType: json['tokenType']?.toString(),
      ownerId: (json['ownerId'] as num?)?.toInt(),
      ownerName: json['ownerName']?.toString(),
      organizationName: json['organizationName']?.toString(),
      email: json['email']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
    );
  }
}
