import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:koye_kos/camp/providers/comment_model.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/models/comment.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';

class CampModel extends RatingProvider with ChangeNotifier {
  Auth auth;
  FirestoreService firestore;
  Camp camp;
  bool _favorited = false;
  double _score = 0;
  List<CampComment> _comments;
  CampComment _userComment;
  StreamSubscription _campSubscription;
  StreamSubscription _favoritedSubscription;
  StreamSubscription _commentsSubscription;

  CampModel(
      {@required this.auth, @required this.firestore, @required this.camp}) {
    _campSubscription = firestore.getCampStream(camp.id).listen(_onCampStream);
    _favoritedSubscription =
        firestore.getCampFavoritedStream(camp.id).listen(_onFavoriteStream);
    _commentsSubscription =
        firestore.getCommentsStream(camp.id).listen(_onComments);
    if (auth.isAuthenticated)
      firestore.getCampRating(camp.id).then((value) {
        _score = value;
        notifyListeners();
      });
  }

  void setAuth(Auth auth) => this.auth = auth;
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
    if (comment == null) return;
    if (comment.commentText.isEmpty) {
      firestore.deleteComment(campId: camp.id);
    } else {
      firestore.addComment(
          campId: camp.id, comment: comment.commentText, score: comment.score);
    }
    firestore.updateRating(campId: camp.id, score: comment.score ?? 0);
    _score = comment.score;
    notifyListeners(); // new score
  }

  void deleteCamp() {
    firestore.deleteCamp(camp.id);
  }

  void setScore(double score) {
    _score = score;
    notifyListeners();
  }

  @override
  void onRated(double score) {
    _score = score;
    notifyListeners();
    firestore.updateRating(campId: camp.id, score: score);
  }

  void _onComments(List<CampComment> comments) {
    _comments = comments
        ?.where((element) => element?.commentText?.isNotEmpty)
        ?.toList();
    _userComment = _comments?.firstWhere(
            (element) => element.userId == auth.user.id,
        orElse: () => null);
  }

// TODO: use streams instead on calling notifylisteners forcing whole tree rebuild
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

class CampPhotoModel with ChangeNotifier {
  final List<String> imageUrls;
  Map<int, ImageProvider> imagesMap = {};
  int startIndex;
  CampPhotoModel({@required this.imageUrls});

  String getUrl(int index) => imageUrls[index];

  ImageProvider getImageProvider(int index) => imagesMap[index];

  void onPhotoLoad(ImageProvider image, int index) {
    imagesMap[index] = image;
  }

  void onPhotoTap(int photoIndex) {
    startIndex = photoIndex;
  }

  bool finishedLoading(int index) => imagesMap.containsKey(index);
}

class CampSimplePhoto with ChangeNotifier {}
