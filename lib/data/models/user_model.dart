// lib/data/models/user_model.dart
class UserModel {
  final String id;
  final String code;
  final String fullName;
  final UserRole role;
  final String? phone;
  final int? age;
  final String? currentLevel;
  final String? targetLevel;
  final bool isNewStudent;
  
  UserModel({
    required this.id,
    required this.code,
    required this.fullName,
    required this.role,
    this.phone,
    this.age,
    this.currentLevel,
    this.targetLevel,
    this.isNewStudent = false,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      code: json['code'],
      fullName: json['fullName'],
      role: UserRole.values.byName(json['role']),
      phone: json['phone'],
      age: json['age'],
      currentLevel: json['currentLevel'],
      targetLevel: json['targetLevel'],
      isNewStudent: json['isNewStudent'] ?? false,
    );
  }
}

enum UserRole { admin, teacher, student }
