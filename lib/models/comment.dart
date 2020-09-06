
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CampComment {
  final String id;
  final String commentText;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final DateTime date;
  double score;
  int reports;

  CampComment({this.id, @required this.commentText, this.userId, this.userName, this.userPhotoUrl, this.date,
    this.score, this.reports});

  factory CampComment.fromFirestore(DocumentSnapshot document) {
    Map data = document.data();
    CampComment comment = CampComment(
      id: document.id,
      commentText: data['comment'] as String,
      userId: data['user_id'] as String,
      userName: data['user_name'] as String,
      userPhotoUrl: data['user_photo_url'] as String,
      date: (data['date'] as Timestamp).toDate(),
    );

    if (data['score'] != null) comment.score = data['score'] as double;
    if (data['reports'] != null) comment.reports = data['reports'] as int;
    return comment;
  }

  @override
  String toString() => '[CampComment(comment: $commentText, score: $score, user: $userName)]';
}
