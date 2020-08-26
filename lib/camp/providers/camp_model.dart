import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:koye_kos/camp/providers/comment_model.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';

class CampModel extends RatingProvider with ChangeNotifier {
  AuthProvider auth;
  FirestoreService firestore;
  Camp camp;
  bool _favorited = false;
  double _score = 0;
  List<CampComment> _comments;
  CampComment _userComment;
  StreamSubscription _campSubscription;
  StreamSubscription _favoritedSubscription;
  StreamSubscription _commentsSubscription;

  CampModel({@required this.auth, @required this.firestore, @required this.camp}) {
    _campSubscription = firestore.getCampStream(camp.id).listen(_onCampStream);
    _favoritedSubscription =
        firestore.getCampFavoritedStream(camp.id).listen(_onFavoriteStream);
    _commentsSubscription =
        firestore.getCommentsStream(camp.id).listen(_onComments);
    firestore.getCampRating(camp.id).then((value) {
      _score = value;
      notifyListeners();
    });
  }

  void setAuth(AuthProvider auth) => this.auth = auth;
  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  void toggleFavorited() {
    _favorited = !_favorited;
    notifyListeners();
    firestore.setFavorited(camp.id, favorited: _favorited);
  }

  bool get favorited => _favorited;
  double get score => _score;
  Stream<List<CampComment>> get comments =>
      firestore.getCommentsStream(camp.id);
  CampComment get userComment => _userComment;
  bool isCreator(String commentId) => commentId == auth.user.id;

  void onCampCommentResult(CampComment comment) {
    if (comment != null)
      firestore.addCampComment(campId: camp.id, comment: comment.commentText);
  }

  void deleteCamp() {
    firestore.deleteCamp(camp.id);
  }

  @override
  void onRated(double score) {
    _score = score;
    notifyListeners();
    firestore.updateRating(camp.id, score);
  }

  void _onComments(List<CampComment> comments) {
    _comments = comments;
    if (comments.isEmpty)
      _userComment = null;
    else
      _userComment = _comments.firstWhere(
          (element) => element.userId == auth.user.id,
          orElse: null);
  }

  void _onCampStream(Camp camp) {
    this.camp = camp;
    notifyListeners();
  }

  void _onFavoriteStream(bool favorited) {
    _favorited = favorited;
    notifyListeners();
  }

  @override
  void dispose() {
    _campSubscription.cancel();
    _favoritedSubscription.cancel();
    _commentsSubscription.cancel();
    super.dispose();
  }
}
