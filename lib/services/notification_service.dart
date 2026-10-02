import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize(String currentUserId) async {
    // 1. Request notification permissions
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted notification permissions');
      }

      // 2. Fetch FCM Token and store in Firestore
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestoreService.updateUserFcmToken(currentUserId, token);
      }

      // 3. Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _firestoreService.updateUserFcmToken(currentUserId, newToken);
      });

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Received foreground notification: ${message.notification?.title}');
        }
      });
    }
  }
}
