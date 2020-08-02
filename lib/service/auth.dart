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

  Future<FirebaseUser> get currentUser => _auth.currentUser();

  void signOut() async {
    _googleSignIn.signOut();
    _auth.signOut();
    _auth.signInAnonymously();
/*    FirebaseAuth.instance.currentUser()
        .then((FirebaseUser user) {
      user.unlinkFromProvider(user.providerId)
    })
        .catchError((onError) => print('ERROR UNLINKING: $onError'));*/
  }

  void signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  Future<bool> signInWithGoogle() async {
    signOut();
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    _auth.signInWithCredential(credential).then((AuthResult result) {
      if (result.user != null) {
        final User user = User(
          id: result.user.uid,
          name: result.user.displayName,
          email: result.user.email,
          photoUrl: result.user.photoUrl,
        );
        FirestoreService.instance.addUser(user);
      }
    });

/*    // TODO: link google account to anonymous user, with updated display name and possibility to unlink later
      _auth.currentUser().then((FirebaseUser user) {
      user.linkWithCredential(credential).then((AuthResult result) {
        print('linked user');
        UserUpdateInfo userInfo = UserUpdateInfo();
        userInfo
          ..displayName = googleUser.displayName
          ..photoUrl = googleUser.photoUrl;
        result.user.updateProfile(userInfo);
        _auth.currentUser().then((value) => print('new din: ${value.displayName}'));
      })
          .catchError((error) {
        print('ERROR LINKING: $error');
      });
  });*/
  }
}
