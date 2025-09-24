/// User model for AgriAI app
/// Represents farmer/buyer users in the system
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String soilType;
  final double landAreaAcres;
  final String userType; // 'farmer' or 'buyer'
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.soilType,
    required this.landAreaAcres,
    required this.userType,
    required this.createdAt,
  });

  /// Create User from Firestore document
  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      soilType: data['soilType'] ?? '',
      landAreaAcres: (data['landAreaAcres'] ?? 0.0).toDouble(),
      userType: data['userType'] ?? 'farmer',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert User to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'soilType': soilType,
      'landAreaAcres': landAreaAcres,
      'userType': userType,
      'createdAt': createdAt,
    };
  }

  /// Convert User to JSON for Firebase
  Map<String, dynamic> toJson() => toFirestore();

  /// Create User from JSON/Firebase data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      soilType: json['soilType'] ?? '',
      landAreaAcres: (json['landAreaAcres'] ?? 0.0).toDouble(),
      userType: json['userType'] ?? 'farmer',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? name,
    String? email,
    String? phone,
    String? soilType,
    double? landAreaAcres,
    String? userType,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      soilType: soilType ?? this.soilType,
      landAreaAcres: landAreaAcres ?? this.landAreaAcres,
      userType: userType ?? this.userType,
      createdAt: createdAt,
    );
  }
}