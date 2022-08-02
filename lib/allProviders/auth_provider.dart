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
  FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference _userRef = FirebaseFirestore.instance.collection('users');

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
    User? user = FirebaseAuth.instance.currentUser;
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn &&
            sharedPreferences.getString(FirestoreConstants.id)?.isNotEmpty ==
                true ||
        user != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> loginHandle(
      {required String email, required String password}) async {
    _status = Status.authenticating;
    notifyListeners();
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    UserChat user = await getUser(userCredential.user!.uid);
    if (user == null) {
      _status = Status.authenticateError;
      return false;
    }
    await sharedPreferences.setString(FirestoreConstants.id, user.id);
    await sharedPreferences.setString(
        FirestoreConstants.nickname, user.nickname);
    await sharedPreferences.setString(
        FirestoreConstants.photoUrl, user.photoUrl);
    await sharedPreferences.setString(FirestoreConstants.aboutMe, user.aboutMe);
    await sharedPreferences.setString(
        FirestoreConstants.phoneNumber, user.phoneNumber);
    print(user);
    _status = Status.authenticated;
    return true;
  }

  Future<UserChat> getUser(String id) async {
    UserChat? user;
    await _userRef.doc(id).get().then((acc) {
      user = UserChat(
        id: id,
        photoUrl: acc.get('photoUrl'),
        nickname: acc.get('username'),
        aboutMe: acc.get('aboutMe'),
        phoneNumber: "",
        loginWith: acc.get('loginWith'),
      );
    });

    return user!;
  }

  Future<bool> registerHandle({
    required String email,
    required String password,
    required String nickname,
  }) async {
    _status = Status.authenticating;
    notifyListeners();
    String photoUrl =
        "https://avatars.abstractapi.com/v1/?api_key=f4964acb34534e2cb2e20829efac27d2&name=$nickname";
    String aboutMe = "";
    String createdAt = DateTime.now().millisecondsSinceEpoch.toString();

    UserChat user = await signUp(
        email: email,
        password: password,
        nickname: nickname,
        aboutMe: aboutMe,
        createdAt: createdAt,
        photoUrl: photoUrl);

    if (user == null) {
      _status = Status.authenticateError;
      return false;
    }
    await sharedPreferences.setString(FirestoreConstants.id, user.id);
    await sharedPreferences.setString(
        FirestoreConstants.nickname, user.nickname);
    await sharedPreferences.setString(
        FirestoreConstants.photoUrl, user.photoUrl);
    await sharedPreferences.setString(FirestoreConstants.aboutMe, user.aboutMe);
    await sharedPreferences.setString(
        FirestoreConstants.phoneNumber, user.phoneNumber);
    print(user);
    _status = Status.authenticated;
    return true;
  }

  Future<UserChat> signUp({
    required String email,
    required String password,
    required String nickname,
    required String photoUrl,
    required String aboutMe,
    required String createdAt,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print(userCredential);

      UserChat user = UserChat(
          id: userCredential.user!.uid,
          photoUrl: photoUrl,
          nickname: nickname,
          aboutMe: aboutMe,
          phoneNumber: "",
          loginWith: "email");

      _userRef.doc(user.id).set({
        'chattingWith': null,
        "createdAt": createdAt,
        'id': user.id,
        'nickname': nickname,
        'photoUrl': photoUrl,
        'loginWith': "email",
      });

      return user;
    } catch (e) {
      throw e;
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
            "loginWith": "google",
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
          // await sharedPreferences.setString("loginWith", currentUser.loginWith ?? "");
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
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _auth.signOut();
      await firebaseAuth.signOut();
    } else {
      await googleSignIn.disconnect();
      await googleSignIn.signOut();
    }
  }
}
