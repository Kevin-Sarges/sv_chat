import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_chat/constants/all_constants.dart';
import 'package:new_chat/model/chat_user.dart';

enum Status {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateCanceled,
}

class AuthProvider extends ChangeNotifier {
  late GoogleSignIn googleSignIn;
  late FirebaseAuth firebaseAuth;
  late FirebaseFirestore firebaseFirestore;
  late SharedPreferences preferences;

  Status _status = Status.uninitialized;

  Status get status => _status;

  AuthProvider({
    required this.googleSignIn,
    required this.firebaseAuth,
    required this.firebaseFirestore,
    required this.preferences,
  });

  String? getFirebaseUserId() {
    return preferences.getString(FirestoreConstants.id);
  }

  Future<bool> isLoggerIn() async {
    bool isLoggerIn = await googleSignIn.isSignedIn();

    if (isLoggerIn &&
        preferences.getString(FirestoreConstants.id)?.isNotEmpty == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> handleGoogleSignIn() async {
    _status = Status.authenticating;
    notifyListeners();

    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? firebaseUser =
          (await firebaseAuth.signInWithCredential(credential)).user;

      if (firebaseUser != null) {
        final QuerySnapshot result = await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
            .get();

        final List<DocumentSnapshot> document = result.docs;
        if (document.isEmpty) {
          firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(firebaseUser.uid)
              .set(
            {
              FirestoreConstants.id: firebaseUser.uid,
              FirestoreConstants.displayName: firebaseUser.displayName,
              FirestoreConstants.photoUrl: firebaseUser.photoURL,
              FirestoreConstants.chattingWith: null,
              "createdAt": DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );

          User? currentUser = firebaseUser;

          await preferences.setString(FirestoreConstants.id, currentUser.uid);
          await preferences.setString(
              FirestoreConstants.displayName, currentUser.displayName ?? '');
          await preferences.setString(
              FirestoreConstants.photoUrl, currentUser.photoURL ?? '');
          await preferences.setString(
              FirestoreConstants.phoneNumber, currentUser.phoneNumber ?? '');
        } else {
          DocumentSnapshot documentSnapshot = document[0];

          ChatUser userChat = ChatUser.fromDocument(documentSnapshot);

          await preferences.setString(FirestoreConstants.id, userChat.id);
          await preferences.setString(
              FirestoreConstants.displayName, userChat.displayName);
          await preferences.setString(
              FirestoreConstants.aboutMe, userChat.aboutMe);
          await preferences.setString(
              FirestoreConstants.phoneNumber, userChat.phoneNumber);
        }

        _status = Status.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }
    } else {
      _status = Status.authenticateCanceled;
      notifyListeners();
      return false;
    }
  }

  Future<void> googleSignOut() async {
    _status = Status.uninitialized;
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
}
