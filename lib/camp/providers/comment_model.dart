import 'package:flutter/foundation.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/models/comment.dart';

abstract class RatingProvider {
  void onRated(double score);
  int get score;
}

class CommentModel extends RatingProvider with ChangeNotifier {
  final String originalText;
  final int originalScore;
  String commentText = '';
  int campScore = 0;
  CommentModel({this.originalText, this.originalScore}) {
    commentText = originalText ?? '';
    campScore = originalScore ?? 0;
  }

  String get title => isNewComment ? 'Add comment or review' : 'Edit review or comment';

  bool get isNewComment => originalText == null && originalScore == null;

  void onTextChange(String text) {
    commentText = text;
  }

  CampComment getComment() {
    return CampComment(commentText: commentText, score: score);
  }

  void deleteComment() {
    // TODO:
    commentText = '';
    campScore = 0;
  }

  @override
  int get score => campScore ?? 0;

  @override
  void onRated(double score) {
    campScore = score.toInt();
    notifyListeners();
  }
}