import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for InvestPro.
///
/// TO SET UP FIREBASE:
/// 1. Go to https://console.firebase.google.com and create a new project
/// 2. Add an Android app with package name "com.investpro.investpro"
/// 3. Download google-services.json and place it in android/app/
/// 4. Add an iOS app with bundle ID "com.investpro.investpro"
/// 5. Download GoogleService-Info.plist and place it in ios/Runner/
/// 6. Enable Email/Password sign-in in Firebase Authentication > Sign-in method
/// 7. (Optional) Enable push notifications in Cloud Messaging
/// 8. Replace the placeholder values below with your actual Firebase project values
///
/// Alternatively, run `flutterfire configure --project=YOUR_PROJECT_ID`
/// to auto-generate this file and download config files.
class FirebaseConfig {
  static FirebaseOptions get androidOptions => const FirebaseOptions(
        apiKey: 'YOUR_API_KEY',
        appId: 'YOUR_APP_ID',
        messagingSenderId: 'YOUR_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        storageBucket: 'your-project.appspot.com',
      );

  static FirebaseOptions get iosOptions => const FirebaseOptions(
        apiKey: 'YOUR_IOS_API_KEY',
        appId: 'YOUR_IOS_APP_ID',
        messagingSenderId: 'YOUR_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        storageBucket: 'your-project.appspot.com',
        iosBundleId: 'com.investpro.investpro',
        iosClientId: 'YOUR_IOS_CLIENT_ID',
      );
}
