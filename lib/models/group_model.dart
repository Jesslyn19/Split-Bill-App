class Group {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final List<String> memberIds;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.memberIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map, String docId) {
    return Group(
      id: docId,
      name: map['name'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      createdBy: map['createdBy'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}
