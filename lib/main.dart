import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'models/user_model.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'views/auth/login_screen.dart';
import 'views/groups/group_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Note: Ensure you configure Firebase via FlutterFire CLI or google-services.json
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(const SplitBillApp());
}

class SplitBillApp extends StatelessWidget {
  const SplitBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Split Bill App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return FutureBuilder<AppUser?>(
          future: FirestoreService().getUserProfile(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final appUser = userSnapshot.data ??
                AppUser(
                  uid: firebaseUser.uid,
                  displayName: firebaseUser.displayName ?? 'User',
                  email: firebaseUser.email ?? '',
                );

            // Register notification permissions on restart
            NotificationService().initialize(appUser.uid);

            return GroupListScreen(currentUser: appUser);
          },
        );
      },
    );
  }
}
