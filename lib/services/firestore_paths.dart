import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePath {
  static String campsPath = 'camps';
  static String picturestPath = 'pictures';
  static String usersPath = 'users';
  static String ratingsPath = 'ratings';
  static String favoritedPath = 'favorited';
  static String commentsPath = 'comments';
  static String reportsPath = 'reports';

  static String getFavoritePath(String userId) {
    return '$usersPath/${userId}/$favoritedPath';
  }

  static String getPicturePath(String campId) {
    return '$campsPath/$campId/$picturestPath';
  }

  static String getRatingPath(String campId) {
    return '$campsPath/${campId}/$ratingsPath';
  }

  static String getCommentsPath(String campId) =>
      '$campsPath/${campId}/$commentsPath';

  static String getCommentReportPath(String campId, String commentId) =>
      '$campsPath/${campId}/$commentsPath/$commentId/$reportsPath';
}

class FirestoragePath {
  static String campsPath = 'camps';

  static String getCampImagesPath(String campId) {
    return '${campsPath}/${campId}';
  }
}