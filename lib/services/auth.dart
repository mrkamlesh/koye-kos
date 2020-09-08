import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'db.dart';
import '../models/user.dart';
import '../models/camp.dart';

enum AuthStatus {
  Unauthenticated, // user = null
  Authenticating, // in process of logging in
  Initialized, // initialized as anon or logged in
  Initializing, //
  Anonymous, // initialized as anon user
  LoggedIn, // user logged in
}

class Auth extends ChangeNotifier {
  AuthService _authService;
  AuthStatus _status = AuthStatus.Unauthenticated;
  StreamSubscription<User> _userStreamSubscription;
  StreamSubscription<UserModel> _userModelStreamSubscription;
  UserModel _user;

  UserModel get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.LoggedIn;
  bool get isInitialized =>
      _status == AuthStatus.LoggedIn ||
      _status == AuthStatus.Anonymous ||
      _status == AuthStatus.Authenticating;

  Auth() {
    print('AUTH constructor');
    _authService = AuthService.instance;
    _userStreamSubscription =
        _authService.userStream.listen(_onAuthStateChanged);
    initialize();
  }

  void initialize() {
    if (_status == AuthStatus.Initializing) return;
    _status = AuthStatus.Initializing;
    //notifyListeners();
    print('INITIALIZE');
    _authService.initializeUser().catchError((error) {
      print('error: $error');
      _status = AuthStatus.Unauthenticated;
      //notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.Authenticating;
    notifyListeners();
    return _authService.signInWithGoogle().then((signedIn) {
      if (!signedIn) {
        _status = AuthStatus.Anonymous;
        notifyListeners();
        return false;
      }
      return true;
    }).catchError((error) {
      _status = AuthStatus.Anonymous;
      notifyListeners();
      return false;
    });
  }

  void signOut() async {
    _status = AuthStatus.Unauthenticated;
    notifyListeners();
    await _authService.signOut(); // _onAuthStateChanged already changes _status
    initialize();
  }

  UserModel _mapUser(User user) {
    if (user == null) return null;
    return UserModel(
        id: user.uid,
        name: user.displayName,
        photoUrl: user.photoURL,
        email: user.email);
  }

  void _onAuthStateChanged(User user) {
    //print('AUTH STATE');
    _user = _mapUser(user);
    if (user == null) {
      _status = AuthStatus.Unauthenticated;
    } else if (user.isAnonymous) {
      _status = AuthStatus.Anonymous;
    } else {
      _status = AuthStatus.LoggedIn;
      _userModelStreamSubscription =
          FirestoreUtils.getUserStream(user.uid).listen((event) {
        print('event!: $event');
        _user = event;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    _userModelStreamSubscription?.cancel();
    super.dispose();
  }
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  User get user => _auth.currentUser;

  Stream<User> get userStream => _auth.userChanges();

  void signOut() async {
    print('signOut ---');
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<User> initializeUser() async {
    print('initializeUser ---');
    return user != null
        ? Future.microtask(() => user)
        : _auth.signInAnonymously().then((result) {
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
      await _auth.currentUser.updateProfile(
          displayName: googleUser.displayName, photoURL: googleUser.photoUrl);
    } on Exception catch (e) {
      await _auth.signInWithCredential(credential).then((result) async {});
    }
    FirestoreUtils.addUser(_auth.currentUser);
    return true;
  }
}
