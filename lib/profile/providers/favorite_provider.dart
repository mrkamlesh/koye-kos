import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';

class FavoriteModel with ChangeNotifier {
  FirestoreService firestore;
  StreamSubscription<List<Favorite>> _favoriteCampIdsSub;
  List<String> _favoriteCampIds;
  String _unfavoritedCampId;

  FavoriteModel({@required this.firestore}) {
    _favoriteCampIdsSub = firestore.campIdsFavoritedStream().listen(_onFavoriteCampIds);
  }

  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  // Favorite
  void _onFavoriteCampIds(List<Favorite> campIds) async {
    _favoriteCampIds = campIds.map((e) => e.campId).toList();
  }

  Stream<List<Favorite>> get favoriteCampIdsStream => firestore.campIdsFavoritedStream();
  Stream<List<Camp>> get favoriteCampsStream => firestore.getCampsStream(_favoriteCampIds);

  void unfavorite(String campId) {
    firestore.setFavorited(campId, favorited: false);
    _unfavoritedCampId = campId;
  }

  void undoFavorite() {
    firestore.setFavorited(_unfavoritedCampId);
  }

  @override
  void dispose() {
    _favoriteCampIdsSub?.cancel();
    super.dispose();
  }
}