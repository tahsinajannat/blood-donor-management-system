class AppUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? area;
  final String? road;
  final String? city;
  final String phone;
  final String email;
  final String bloodGroup;
  final String? dateOfBirth;
  final String? lastDonationDate;
  final bool isVerified;
  final bool isActiveDonor;
  final String? createdAt;
  final String? updatedAt;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.area,
    this.road,
    this.city,
    required this.phone,
    required this.email,
    required this.bloodGroup,
    this.dateOfBirth,
    this.lastDonationDate,
    this.isVerified = false,
    this.isActiveDonor = false,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => "$firstName $lastName".trim();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      area: json['area'],
      road: json['road'],
      city: json['city'],
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      dateOfBirth: json['date_of_birth']?.toString(),
      lastDonationDate: json['last_donation_date']?.toString(),
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isActiveDonor:
          json['is_active_donor'] == true || json['is_active_donor'] == 1,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
