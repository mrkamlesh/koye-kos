import 'package:flutter/foundation.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';

import 'camp_model.dart';

abstract class RatingProvider {
  void onRated(double score);
  double get score;
}

class CommentModel extends RatingProvider with ChangeNotifier {
  CampComment comment;
  CommentModel({this.comment}) {
  }

  String get title => comment == null ? 'Add comment' : 'Edit comment';

  @override
  double get score => comment?.score ?? 0;

  @override
  void onRated(double score) {
    comment.score = score;
    notifyListeners();
  }
}