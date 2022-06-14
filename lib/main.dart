import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:new_chat/firebase_options.dart';
import 'package:new_chat/providers/auth_provider.dart';
import 'package:new_chat/providers/chat_provider.dart';
import 'package:new_chat/providers/home_provider.dart';
import 'package:new_chat/providers/profile_provider.dart';
import 'package:new_chat/screens/splash_page.dart';
import 'package:new_chat/utilities/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MyApp(
    preferences: prefs,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences preferences;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  MyApp({Key? key, required this.preferences}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            firebaseFirestore: firebaseFirestore,
            preferences: preferences,
            googleSignIn: GoogleSignIn(),
            firebaseAuth: FirebaseAuth.instance,
          ),
        ),
        Provider<ProfileProvider>(
          create: (_) => ProfileProvider(
            preferences: preferences,
            firebaseFirestore: firebaseFirestore,
            firebaseStorage: firebaseStorage,
          ),
        ),
        Provider<HomeProvider>(
          create: (_) => HomeProvider(
            firebaseFirestore: firebaseFirestore,
          ),
        ),
        Provider<ChatProvider>(
          create: (_) => ChatProvider(
            preferences: preferences,
            firebaseStorage: firebaseStorage,
            firebaseFirestore: firebaseFirestore,
          ),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SVchat',
        theme: appTheme,
        home: const SplashPage(),
      ),
    );
  }
}
