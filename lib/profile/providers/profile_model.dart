import 'package:flutter/cupertino.dart';
import 'package:koye_kos/models/user.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';

class ProfileModel with ChangeNotifier {
  Auth auth;
  FirestoreService firestore;

  ProfileModel({@required this.auth, @required this.firestore});

  void setAuth(Auth auth) => this.auth = auth;
  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  bool get loggedIn => auth.status == AuthStatus.LoggedIn;
  bool get authenticating => auth.status == AuthStatus.Authenticating;
  UserModel get user => auth.user;

  void google() => auth.signInWithGoogle();

  void signOut() => auth.signOut();
}