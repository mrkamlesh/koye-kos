import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import '../models.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  final User user = User();

  User get currentUser => user;

  // Populate user object, either with logged in user or a new anon
  Future<User> initializeUser() {
    if (user.firebaseUser != null) {
      return Future.microtask(() => user);
    } else {
      return _auth.currentUser().then((currentUser) {
        if (currentUser == null) {
          signInAnonymously().then((anonUser) {
            user.setFirebaseUser(anonUser);
          });
        } else {
          user.setFirebaseUser(currentUser);
        }
        return user;
      });
    }
  }

  void signOut() async {
    _googleSignIn.signOut();
    _auth.signOut();
    user.firebaseUser = null;
    initializeUser();
    user.setLoggedIn(loggedIn: false);
  }

  Future<FirebaseUser> signInAnonymously() async {
    return _auth.signInAnonymously().then((result) {
      user.setLoggedIn(loggedIn: false);
      return result.user;
    });
  }

  Future<bool> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false; // user exited
    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.currentUser().then((user) async {
      if (user.providerData.map((e) => e.providerId).contains('google.com')) {
        await user.unlinkFromProvider('google.com');
      }
      try {
        _auth.signInWithCredential(credential);
      } on Exception catch(e) {
        await user.linkWithCredential(credential);
      }
    });
    UserUpdateInfo userInfo = UserUpdateInfo();
    userInfo
      ..displayName = googleUser.displayName
      ..photoUrl = googleUser.photoUrl;
    await _auth.currentUser().then((user) async {
      await user.updateProfile(userInfo);
    });
    _auth.currentUser().then((user) async {
      this.user.setFirebaseUser(user);
      await FirestoreService.instance.addUser(this.user);
      this.user.setLoggedIn(loggedIn: true);
    });
  }
}
