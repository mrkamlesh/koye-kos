import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';

class FavoriteModel with ChangeNotifier {
  FirestoreService firestore;
  StreamSubscription<List<Favorite>> _favoriteCampIdsSub;
  List<String> _favoriteCampIds;
  // Map camp id to 'position' in list, where a position 0 is the most recent favorited id. 
  // Used to sort (a general) camp stream based on user favorited data. 
  Map<String, int> _campIdToFavoritedPosition;
  String _unfavoritedCampIdTemp;  // temporarily store the most recent unfavorited camp id

  FavoriteModel({@required this.firestore}) {
    _favoriteCampIdsSub =
        firestore.campIdsFavoritedStream().listen(_onFavoriteCampIds);
  }

  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  // Favorite
  void _onFavoriteCampIds(List<Favorite> campIds) async {
    _favoriteCampIds = campIds.map((e) => e.campId).toList();
    _campIdToFavoritedPosition =
        _favoriteCampIds.asMap().map((position, id) => MapEntry(id, position));
  }

  Stream<List<Favorite>> get favoriteCampIdsStream =>
      firestore.campIdsFavoritedStream();
  // Sort based on favorited time
  Stream<List<Camp>> get favoriteCampsStream {
    return firestore.getCampsStream(_favoriteCampIds).map((event) {
      event.sort((a, b) => _campIdToFavoritedPosition[a.id] - _campIdToFavoritedPosition[b.id]);
      return event;
    });
  }

  void unfavorite(String campId) {
    firestore.setFavorited(campId, favorited: false);
    _unfavoritedCampIdTemp = campId;
  }

  void undoFavorite() {
    firestore.setFavorited(_unfavoritedCampIdTemp);
  }

  @override
  void dispose() {
    _favoriteCampIdsSub?.cancel();
    super.dispose();
  }
}
