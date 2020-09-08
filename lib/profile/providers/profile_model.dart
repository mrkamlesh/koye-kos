import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:koye_kos/models/user.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';

import '../profile.dart';

enum NetworkState { Unknown, Connected, Disconnected }

class ProfileModel with ChangeNotifier {
  Auth auth;
  FirestoreService firestore;
  StreamSubscription ss;
  NetworkState _state = NetworkState.Unknown;

  ProfileModel({@required this.auth, @required this.firestore}) {
    ss = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      _state = NetworkState.Disconnected;
    } else if (result == ConnectivityResult.wifi || result == ConnectivityResult.mobile) {
      _state = NetworkState.Connected;
    } else {
      _state = NetworkState.Unknown;
    }
    print('updated network state');
    notifyListeners();
  }

  void setAuth(Auth auth) => this.auth = auth;
  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  bool get loggedIn => auth.status == AuthStatus.LoggedIn;
  bool get authenticating => auth.status == AuthStatus.Authenticating;
  UserModel get user => auth.user;
  bool get hasNetwork => _state == NetworkState.Connected;

  Future<bool> login({@required LoginProvider provider}) {
    if (provider == LoginProvider.Google) return google();
    else return Future.microtask(() => false);
  }

  Future<bool> google() => auth.signInWithGoogle();

  void signOut() => auth.signOut();

  @override
  void dispose() {
    ss?.cancel();
    super.dispose();
  }
}