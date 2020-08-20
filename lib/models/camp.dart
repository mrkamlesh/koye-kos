import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils.dart';

class Camp {
  final String id;
  final List<String> imageUrls;
  final LatLng location;
  final double score;
  final int ratings;  // save as list of scores?
  final String description;
  final String creatorId;
  final String creatorName;
  // time created?

  Camp(
      {@required this.id,
        @required this.imageUrls,
        @required this.location,
        this.score = 0.0,
        this.ratings = 0,
        @required this.description,
        @required this.creatorId,
        @required this.creatorName});

  factory Camp.fromFirestore(DocumentSnapshot document) {
    Map data = document.data();
    LatLng location = ((data['location'] ?? GeoPoint(0, 0)) as GeoPoint).toLatLng();
    // Fix this when null safety comes to Dart..
    return Camp(
        id: document.id ?? '',
        imageUrls: List<String>.from((data['image_urls'] ?? []) as List),
        location: location,
        score: ((data['score'] ?? 0) as num).toDouble(),
        ratings: data['ratings'] as int ?? 0,
        description: data['description'] as String ?? '',
        creatorId: data['creator_id'] as String ?? '',
        creatorName: data['creator_name'] as String ?? '');
  }

  Map<String, dynamic> toFirestoreMap() {
    HashMap<String, dynamic> map = HashMap();
    // Note: id is left out since it is already saved as the documents name in firestore
    map.addAll({
      'image_urls': imageUrls,  // can't be empty
      'location': location.toGeoPoint(), // can't be empty
      'description': description,  // can't be empty
      'creator_id': creatorId, // can't be empty
      'creator_name': creatorName,  // can't be empty
      'score': score,
      'ratings': ratings,
    });
    return map;
  }

  @override
  String toString() {
    return "[Camp ($location $score $ratings $description $imageUrls)]";
  }
}

class CampComment {
  final String comment;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final DateTime date;
  double score;

  CampComment({this.comment, this.userId, this.userName, this.userPhotoUrl, this.date,
  this.score});

  factory CampComment.fromFirestore(DocumentSnapshot document) {
    Map data = document.data();
    CampComment comment = CampComment(
      comment: data['comment'] as String,
      userId: data['user_id'] as String,
      userName: data['user_name'] as String,
      userPhotoUrl: data['user_photo_url'] as String,
      date: (data['date'] as Timestamp).toDate(),
    );
    if (data['score'] != null) comment.score = data['score'] as double;
    return comment;
  }
}


class Favorite {
  final String campId;
  final Timestamp time;

  Favorite({this.campId, this.time});

  factory Favorite.fromFirestore(DocumentSnapshot document) {
    return Favorite(
        campId: document.id,
        time: document.data()['time'] as Timestamp);
  }
}


