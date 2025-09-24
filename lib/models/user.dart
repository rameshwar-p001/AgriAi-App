/// User model for AgriAI app
/// Represents farmer/buyer users in the system
class User {
  final String id;
  final String name;
  final String email;
  final String soilType;
  final List<String> preferredCrops;
  final String userType; // 'farmer' or 'buyer'
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.soilType,
    required this.preferredCrops,
    required this.userType,
    required this.createdAt,
  });

  /// Create User from Firestore document
  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    return User(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      soilType: data['soilType'] ?? '',
      preferredCrops: List<String>.from(data['preferredCrops'] ?? []),
      userType: data['userType'] ?? 'farmer',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert User to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'soilType': soilType,
      'preferredCrops': preferredCrops,
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
      soilType: json['soilType'] ?? '',
      preferredCrops: List<String>.from(json['preferredCrops'] ?? []),
      userType: json['userType'] ?? 'farmer',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? name,
    String? email,
    String? soilType,
    List<String>? preferredCrops,
    String? userType,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      soilType: soilType ?? this.soilType,
      preferredCrops: preferredCrops ?? this.preferredCrops,
      userType: userType ?? this.userType,
      createdAt: createdAt,
    );
  }
}