import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:madee_chat_app/allConstants/constants.dart';
import 'package:madee_chat_app/allConstants/firestore_constants.dart';
import 'package:madee_chat_app/allModels/user_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Status {
  unitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateCanceled,
}

class AuthProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences sharedPreferences;

  Status _status = Status.unitialized;

  Status get status => _status;

  AuthProvider({
    required this.googleSignIn,
    required this.firebaseAuth,
    required this.firebaseFirestore,
    required this.sharedPreferences,
  });

  String? getUserFirebaseId() {
    return sharedPreferences.getString(FirestoreConstants.id);
  }

  Future<bool> isLoggedIn() async {
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn &&
        sharedPreferences.getString(FirestoreConstants.id)?.isNotEmpty ==
            true) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> handleSigin() async {
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
        if (document.length == 0) {
          firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(firebaseUser.uid)
              .set({
            FirestoreConstants.nickname: firebaseUser.displayName,
            FirestoreConstants.photoUrl: firebaseUser.photoURL,
            FirestoreConstants.id: firebaseUser.uid,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
            FirestoreConstants.chattingWith: null,
          });

          User? currentUser = firebaseUser;
          await sharedPreferences.setString(
              FirestoreConstants.id, currentUser.uid);

          await sharedPreferences.setString(
              FirestoreConstants.nickname, currentUser.displayName ?? "");

          await sharedPreferences.setString(
              FirestoreConstants.photoUrl, currentUser.photoURL ?? "");
          await sharedPreferences.setString(
              FirestoreConstants.phoneNumber, currentUser.phoneNumber ?? "");
        } else {
          DocumentSnapshot documentSnapshot = document[0];
          UserChat userchat = UserChat.fromDocument(documentSnapshot);

          await sharedPreferences.setString(FirestoreConstants.id, userchat.id);
          await sharedPreferences.setString(
              FirestoreConstants.nickname, userchat.nickname);
          await sharedPreferences.setString(
              FirestoreConstants.photoUrl, userchat.photoUrl);
          await sharedPreferences.setString(
              FirestoreConstants.aboutMe, userchat.aboutMe);
          await sharedPreferences.setString(
              FirestoreConstants.phoneNumber, userchat.phoneNumber);
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

  Future<void> handleSignOut() async {
    _status = Status.unitialized;
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
}
