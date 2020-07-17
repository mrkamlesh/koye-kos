import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:koye_kos/models.dart';
import 'package:provider/provider.dart';

import 'db.dart';

class SignInWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<FirebaseUser>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    print('is anonomous: ${user?.isAnonymous}');
    print('name ${user?.displayName}');
    final _signedIn = user != null ? !user.isAnonymous : false;
    print(_signedIn);
    return FlatButton(
      child: _signedIn ? Text('Log out') : Text('Log in with Google'),
      onPressed: () {
        return _signedIn
            ? AuthService.signOut()
            : AuthService.signInWithGoogle();
      },
      textColor: Theme.of(context).buttonColor,
    );
  }
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static void signOut() async {
    await _auth.currentUser().then((value) {
      value.unlinkFromProvider(value.providerId);
    });
    /*await _auth.signOut();
    await _auth.signInAnonymously();*/
  }

  static void signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  static void signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    _auth.currentUser().then((FirebaseUser user) {
      user.linkWithCredential(credential).then((AuthResult result) {
        print('linked user');
        print(result.user.displayName);
        //assert(result.user.displayName != null); // simple check sign in works
      });
      print(user);
    });

  }
}
