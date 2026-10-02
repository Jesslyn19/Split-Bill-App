class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    return AppUser(
      uid: docId,
      displayName: map['displayName'] ?? 'Member',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
    );
  }
}
