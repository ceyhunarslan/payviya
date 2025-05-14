class User {
  final int id;
  final String email;
  final String name;
  final String surname;
  final bool isActive;
  final bool isAdmin;
  final DateTime? createdAt;
  final String? phoneNumber;
  final String? countryCode;
  final String? profileImage;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.surname,
    required this.isActive,
    this.isAdmin = false,
    this.createdAt,
    this.phoneNumber,
    this.countryCode,
    this.profileImage,
  });

  // Full name helper
  String get fullName => '$name $surname';

  // First letter of names for avatar
  String get initials {
    final nameInitial = name.isNotEmpty ? name[0] : '';
    final surnameInitial = surname.isNotEmpty ? surname[0] : '';
    return '$nameInitial$surnameInitial'.toUpperCase();
  }

  // Factory constructor to create a User object from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      isActive: json['is_active'] ?? true,
      isAdmin: json['is_admin'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      phoneNumber: json['phone_number'],
      countryCode: json['country_code'],
      profileImage: json['profile_image'],
    );
  }

  // Convert User object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'surname': surname,
      'is_active': isActive,
      'is_admin': isAdmin,
      'created_at': createdAt?.toIso8601String(),
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'profile_image': profileImage,
    };
  }
} 