import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePath {
  static String campsPath = 'camps';
  static String usersPath = 'users';
  static String ratingsPath = 'ratings';
  static String favoritedPath = 'favorited';
  static String commentsPath = 'comments';

  static String getFavoritePath(String userId) {
    return '$usersPath/${userId}/$favoritedPath';
  }

  static String getRatingPath(String campId) {
    return '$campsPath/${campId}/$ratingsPath';
  }

  static String getCommentsPath(String campId) =>
      '$campsPath/${campId}/$commentsPath';
}

class FirestoragePath {
  static String campsPath = 'camps';

  static String getCampImagesPath(String campId) {
    return '${campsPath}/${campId}';
  }
}