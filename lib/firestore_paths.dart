import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePath {
  static String getFavoritePath(String userId) {
    return 'users/${userId}/favorited';
  }
}