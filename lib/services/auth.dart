import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'db.dart';
import '../models/user.dart';
import '../models/camp.dart';

enum AuthStatus {
  Uninitialized,
  Anonymous,
  Authenticating,
  Authenticated,
  Unauthenticated
}

class AuthProvider extends ChangeNotifier {
  AuthService _authService;
  AuthStatus _status = AuthStatus.Uninitialized;

  Stream<UserModel> get userStream => _authService.userStream.map(_mapUserStream);
  AuthStatus get status => _status;

  AuthProvider() {
    _authService = AuthService.instance;
    _authService.userStream.listen(_onAuthStateChanged);
    _authService.signInAnonymously();
  }

  UserModel _mapUserStream(User user) {
    if (user == null) return null;
    return UserModel(
      id: user.uid,
      name: user.displayName,
      photoUrl: user.photoURL,
      email: user.email
    );
  }

  void _onAuthStateChanged(User user) {
    print('AuthProvider user: $user');
    if (user.isAnonymous) {
      _status = AuthStatus.Anonymous;
    } else if (user.displayName != null) {
      _status = AuthStatus.Authenticated;
    } else {
      _status = AuthStatus.Unauthenticated;
    }
    notifyListeners();
  }
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  User getUser () => _auth.currentUser;

  Stream<User> get userStream => _auth.userChanges();

  void signOut() async {
    _googleSignIn.signOut();
    _auth.signOut();
  }

  Future<User> signInAnonymously() async {
    return _auth.signInAnonymously().then((result) {
      return result.user;
    });
  }

  Future<bool> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false; // user exited
    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      // Try to upgrade anonymous user, if fail, user already have an account, so sign them into that one.
      await _auth.currentUser.linkWithCredential(credential);
      await _auth.currentUser.updateProfile(displayName: googleUser.displayName, photoURL: googleUser.photoUrl);

    } on Exception catch(e) {
      _auth.signInWithCredential(credential).then((result) async {
      });
    }
    return true;
  }
}
