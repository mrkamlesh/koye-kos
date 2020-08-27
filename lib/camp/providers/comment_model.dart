import 'package:flutter/foundation.dart';
import 'package:koye_kos/models/camp.dart';


abstract class RatingProvider {
  void onRated(double score);
  double get score;
}

class CommentModel extends RatingProvider with ChangeNotifier {
  CampComment comment;
  String commentText;
  double campScore;
  CommentModel({this.comment}) {
    commentText = comment?.commentText;
    campScore = comment?.score;
  }

  String get title => comment == null ? 'Add comment' : 'Edit comment';

  void onTextChange(String text) {
    commentText = text;
  }

  CampComment getComment() {
    return CampComment(commentText: commentText, score: score);
  }

  @override
  double get score => campScore ?? 0;

  @override
  void onRated(double score) {
    campScore = score;
    notifyListeners();
  }
}