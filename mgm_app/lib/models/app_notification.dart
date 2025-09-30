class AppNotification {
  const AppNotification({
    required this.id,
    required this.inviterUid,
    required this.inviterCode,
    required this.invitedName,
    required this.pointsAwarded,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String inviterUid;
  final String inviterCode;
  final String invitedName;
  final int pointsAwarded;
  final String type;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      inviterUid: json['inviter_uid'] as String,
      inviterCode: json['inviter_code'] as String,
      invitedName: json['invited_name'] as String? ?? '',
      pointsAwarded: (json['points_awarded'] as num).toInt(),
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inviter_uid': inviterUid,
      'inviter_code': inviterCode,
      'invited_name': invitedName,
      'points_awarded': pointsAwarded,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
