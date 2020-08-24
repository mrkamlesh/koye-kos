

import 'package:flutter/cupertino.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/db.dart';

class CampModel extends ChangeNotifier {
  FirestoreService firestore;
  Camp camp;
  bool _favorited = false;
  double _score = 0;
  CampModel({@required this.firestore, @required this.camp}) {
    firestore.getCampStream(camp.id).listen(_onCampStream);
    firestore.getCampFavoritedStream(camp.id).listen(_onFavoriteStream);
    firestore.getCampRating(camp.id).then((value) {
      _score = value;
      notifyListeners();
    });
  }

  void setFirestore(FirestoreService firestore) => this.firestore = firestore;
  
  void toggleFavorited() {
    _favorited = !_favorited;
    notifyListeners();
    firestore.setFavorited(camp.id, favorited: _favorited);
  }

  bool get favorited => _favorited;
  double get score => _score;

  void setScore(double score) {
    _score = score;
    notifyListeners();
    firestore.updateRating(camp.id, score);
  }

  void deleteCamp() {
    firestore.deleteCamp(camp.id);
  }

  void _onCampStream(Camp camp) {
    this.camp = camp;
    notifyListeners();
  }

  void _onFavoriteStream(bool favorited) {
    _favorited = favorited;
    notifyListeners();
  }
}