import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/models/user.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';

class ProfileModel with ChangeNotifier {
  Auth auth;
  FirestoreService firestore;
  StreamSubscription<List<Favorite>> _favoriteCampIdsSub;
  List<String> _favoriteCampIds;

  ProfileModel({@required this.auth, @required this.firestore}) {
    _favoriteCampIdsSub = firestore.campIdsFavoritedStream().listen(_onFavoriteCampIds);
  }

  void setAuth(Auth auth) => this.auth = auth;
  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  bool get loggedIn => auth.status == AuthStatus.LoggedIn;
  bool get authenticating => auth.status == AuthStatus.Authenticating;
  UserModel get user => auth.user;

  void google() => auth.signInWithGoogle();

  void signOut() => auth.signOut();

  // Favorite
  void _onFavoriteCampIds(List<Favorite> campIds) async {
    _favoriteCampIds = campIds.map((e) => e.campId).toList();
  }

  Stream<List<Favorite>> get favoriteCampIdsStream => firestore.campIdsFavoritedStream();
  Stream<List<Camp>> get favoriteCampsStream => firestore.getCampsStream(_favoriteCampIds);

  void unfavorite(String campId) {
    firestore.setFavorited(campId, favorited: false);
  }

  @override
  void dispose() {
    _favoriteCampIdsSub?.cancel();
    super.dispose();
  }
}