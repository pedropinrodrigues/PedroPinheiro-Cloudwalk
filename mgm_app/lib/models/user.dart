class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.sex,
    required this.age,
    required this.myCode,
    required this.pointsTotal,
    required this.createdAt,
    required this.updatedAt,
    required this.passwordHash,
    this.invitedByCode,
  });

  final String uid;
  final String name;
  final String email;
  final String sex;
  final int age;
  final String myCode;
  final int pointsTotal;
  final String? invitedByCode;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      sex: json['sex'] as String,
      age: (json['age'] as num).toInt(),
      myCode: json['my_code'] as String,
      pointsTotal: (json['points_total'] as num).toInt(),
      invitedByCode: json['invited_by_code'] as String?,
      passwordHash: json['password_hash'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'sex': sex,
      'age': age,
      'my_code': myCode,
      'points_total': pointsTotal,
      'invited_by_code': invitedByCode,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? sex,
    int? age,
    String? myCode,
    int? pointsTotal,
    String? invitedByCode,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      myCode: myCode ?? this.myCode,
      pointsTotal: pointsTotal ?? this.pointsTotal,
      invitedByCode: invitedByCode ?? this.invitedByCode,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
