# Split Bill App (Flutter & Firebase)

A smart, fair bill splitting application built with Flutter and Firebase.

## ✨ Features
1. **Snap a Picture of the Bill**: Upload/take a photo of the receipt using Camera or Gallery, parsed automatically using Gemini Flash AI or Google ML Kit OCR.
2. **Invite People into a Group**: Create groups with short 6-character alphanumeric invite codes (e.g. `X7K9P2`) and share directly via WhatsApp/Telegram.
3. **Item Assignment**: Assign members to individual line items. Easily split items among multiple people with automatic equal divisions.
4. **Fair Proportional Calculations**: Proportionally allocates tax, service charges, and discounts based on what each member spent.
5. **Push Notifications**: Firebase Cloud Function automatically sends individual Firebase Cloud Messaging (FCM) notifications to each member with their exact share amount.
6. **Summary & Sharing**: Export formatted breakdown text to WhatsApp, Telegram, or SMS.

---

## 📁 Project Structure
```
4_SPLIT_BILL_APP/
├── pubspec.yaml
├── lib/
│   ├── main.dart                          # App entry point & auth gate
│   ├── core/
│   │   ├── constants/app_colors.dart      # Design palette
│   │   └── utils/bill_calculator.dart     # Proportional split calculation engine
│   ├── models/
│   │   ├── user_model.dart                # User profile & FCM token
│   │   ├── group_model.dart               # Groups & invite codes
│   │   └── bill_model.dart                # Bill, items & member shares
│   ├── services/
│   │   ├── auth_service.dart              # Firebase Auth
│   │   ├── firestore_service.dart         # Firestore operations
│   │   ├── receipt_scanner_service.dart   # Gemini Flash AI + ML Kit OCR
│   │   └── notification_service.dart      # FCM token sync & listener
│   └── views/
│       ├── auth/login_screen.dart         # Quick guest profile setup
│       ├── groups/group_list_screen.dart  # Group list & invite code sharing
│       └── bill/
│           ├── scan_receipt_screen.dart   # OCR scanning & manual adjustment
│           ├── assign_items_screen.dart   # Assign items to people
│           └── bill_summary_screen.dart   # Member breakdown & push triggers
└── functions/
    ├── package.json
    └── index.js                           # Cloud Function sending FCM notifications
```

---

## 🚀 Setup & Getting Started

### 1. Flutter Setup
Ensure Flutter SDK is added to your environment `PATH`:
- If not installed, download it from [https://flutter.dev](https://flutter.dev).
- Verify in your terminal:
  ```bash
  flutter doctor
  ```

### 2. Connect to Firebase
1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. Run configuration in this directory:
   ```bash
   flutterfire configure
   ```
   *(Select your Firebase project; it will generate `lib/firebase_options.dart`)*

3. In Firebase Console:
   - Enable **Authentication** (Anonymous and/or Email/Password).
   - Enable **Cloud Firestore** in test/production mode.
   - Enable **Firebase Cloud Messaging (FCM)**.

### 3. Deploy Notification Cloud Function
```bash
cd functions
npm install
firebase deploy --only functions
```

### 4. Run the App
```bash
flutter pub get
flutter run
```
