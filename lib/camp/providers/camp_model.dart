import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/models/comment.dart';
import 'package:koye_kos/models/image.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';

class CampModel with ChangeNotifier {
  Auth auth;
  FirestoreService firestore;
  Camp camp;
  bool _favorited = false;
  int _score = 0;
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
  int get score => _score;
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
    if (userComment?.score != comment.score) {
      firestore.updateRating(campId: camp.id, score: comment.score ?? 0);
      _score = comment.score;
      notifyListeners(); // new score
    }
  }

  void deleteCamp() {
    firestore.deleteCamp(camp.id);
  }

  void setScore(int score) {
    _score = score;
    notifyListeners();
  }

  bool commentReported(String commentId) {
    return auth?.user?.commentsReported?.contains(commentId) ?? false;
  }

  void onReportPressed(String commentId, {bool reported = true}) {
    reported
        ? firestore.reportComment(campId: camp.id, commentId: commentId)
        : firestore.reportCommentRemove(campId: camp.id, commentId: commentId);
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
    _campSubscription?.cancel();
    _favoritedSubscription?.cancel();
    _commentsSubscription?.cancel();
    super.dispose();
  }
}

class CampPhotoModel with ChangeNotifier {
  Auth auth;
  FirestoreService firestore;

  final String campId;
  StreamSubscription _imagesSubscription;
  List<ImageData> _imageData = [];
  Stream<List<ImageData>> _imageDataStream;
  Map<int, ImageProvider> _imagesMap = {};
  int _startIndex;
  CampPhotoModel({@required this.auth, @required this.firestore, @required this.campId}) {
    _imagesSubscription = firestore.getCampImagesStream(campId).listen(_onImageData);
  }

  void _onImageData(List<ImageData> data) {
    _imageData = data;
    notifyListeners();
  }

  void setAuth(Auth auth) => this.auth = auth;
  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  List<String> get imageUrls => _imageData.map((data) => data.imageUrl).toList();
  String getUrl(int index) => _imageData[index]?.imageUrl;
  int get imagesCount => _imageData.length;
  int get startIndex => _startIndex;

  ImageProvider getImageProvider(int index) => _imagesMap[index];

  void onPhotoLoad(ImageProvider image, int index) {
    _imagesMap[index] = image;
  }

  void onPhotoTap(int photoIndex) {
    _startIndex = photoIndex;
  }

  void onReportPressed(double indexValue, {bool reported = true}) {
    final index = indexValue.round();
    reported
        ? firestore.reportImage(campId: campId, imageId: _imageData[index].path)
        : firestore.reportImageRemove(campId: campId, imageId: _imageData[index].path);
  }

  bool imageReported(double indexValue) {
    final index = indexValue.round();
    return auth.isAuthenticated && auth.user.imagesReported.contains(_imageData[index].path);
  }

  @override
  void dispose() {
    _imagesSubscription?.cancel();
    super.dispose();
  }
}