import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/bill_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= USER OPERATIONS =================
  Future<void> saveUserProfile(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateUserFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<List<AppUser>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final List<AppUser> users = [];
    // Firestore whereIn has limit of 10-30, so chunking if needed
    for (int i = 0; i < uids.length; i += 10) {
      final chunk = uids.sublist(i, min(i + 10, uids.length));
      final snapshot = await _db.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
      users.addAll(snapshot.docs.map((d) => AppUser.fromMap(d.data(), d.id)));
    }
    return users;
  }

  // ================= GROUP OPERATIONS =================
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<Group> createGroup({
    required String name,
    required String creatorUid,
  }) async {
    final docRef = _db.collection('groups').doc();
    final inviteCode = _generateInviteCode();

    final group = Group(
      id: docRef.id,
      name: name,
      inviteCode: inviteCode,
      createdBy: creatorUid,
      memberIds: [creatorUid],
      createdAt: DateTime.now(),
    );

    await docRef.set(group.toMap());
    return group;
  }

  Stream<List<Group>> streamUserGroups(String uid) {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => Group.fromMap(d.data(), d.id)).toList());
  }

  Future<Group> joinGroupByCode({
    required String inviteCode,
    required String uid,
  }) async {
    final query = await _db
        .collection('groups')
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid invite code. Group not found.');
    }

    final doc = query.docs.first;
    await doc.reference.update({
      'memberIds': FieldValue.arrayUnion([uid]),
    });

    final updated = await doc.reference.get();
    return Group.fromMap(updated.data()!, updated.id);
  }

  // ================= BILL OPERATIONS =================
  Future<void> saveBill(Bill bill) async {
    await _db.collection('bills').doc(bill.id).set(bill.toMap(), SetOptions(merge: true));
  }

  Stream<Bill?> streamBill(String billId) {
    return _db.collection('bills').doc(billId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Bill.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<Bill>> streamGroupBills(String groupId) {
    return _db
        .collection('bills')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => Bill.fromMap(d.data(), d.id)).toList());
  }
}
