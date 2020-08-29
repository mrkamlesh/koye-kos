import 'package:flutter/foundation.dart';
import 'package:koye_kos/models/camp.dart';


abstract class RatingProvider {
  void onRated(double score);
  double get score;
}

class CommentModel extends RatingProvider with ChangeNotifier {
  final String originalText;
  final double originalScore;
  String commentText;
  double campScore;
  CommentModel({this.originalText, this.originalScore}) {
    commentText = originalText ?? '';
    campScore = originalScore ?? null;
  }

  String get title => isNewComment ? 'Add comment' : 'Edit comment';

  bool get isNewComment =>  originalText == null;

  void onTextChange(String text) {
    commentText = text;
  }

  CampComment getComment() {
    return CampComment(commentText: commentText, score: score);
  }

  void deleteComment() {
    // TODO:
    commentText = '';
  }

  @override
  double get score => campScore ?? 0;

  @override
  void onRated(double score) {
    campScore = score;
    notifyListeners();
  }
}