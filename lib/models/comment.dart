
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CampComment {
  final String commentText;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final DateTime date;
  double score;
  int likes;
  int dislikes;
  int reports;

  CampComment({@required this.commentText, this.userId, this.userName, this.userPhotoUrl, this.date,
    this.score, this.likes, this.dislikes, this.reports});

  factory CampComment.fromFirestore(DocumentSnapshot document) {
    Map data = document.data();
    CampComment comment = CampComment(
      commentText: data['comment'] as String,
      userId: data['user_id'] as String,
      userName: data['user_name'] as String,
      userPhotoUrl: data['user_photo_url'] as String,
      date: (data['date'] as Timestamp).toDate(),
    );
    if (data['score'] != null) comment.score = data['score'] as double;
    if (data['likes'] != null) comment.score = data['likes'] as double;
    if (data['dislikes'] != null) comment.score = data['dislikes'] as double;
    if (data['reports'] != null) comment.score = data['reports'] as double;
    return comment;
  }

  @override
  String toString() => '[CampComment(comment: $commentText, score: $score, user: $userName)]';
}
