import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class SignInWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<FirebaseUser>(context);
    final _signedIn = user != null;
    return FlatButton(
      child: _signedIn ? Text('Log out') : Text('Log in'),
      onPressed: () => _signedIn ? AuthService.signOut() : AuthService.signInWithGoogle(),
      textColor: Theme.of(context).buttonColor,
    );
  }
}


class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static void signOut() async {
    await _auth.signOut();
  }

  static void signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    assert(user.displayName != null);  // simple check sign in works
  }
}


