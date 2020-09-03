import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils.dart';

enum CampFeature { Tent, Hammock, Water }

// TODO: this could need some code generation
class Camp {
  final String id;
  final List<String> imageUrls;
  final Point<double> location;
  final double score;
  final int ratings;  // save as list of scores?
  final String description;
  final String creatorId;
  final String creatorName;
  Set<CampFeature> types;

  Camp(
      {@required this.id,
        @required this.imageUrls,
        @required this.location,
        this.score = 0.0,
        this.ratings = 0,
        @required this.description,
        @required this.creatorId,
        @required this.creatorName,
        @required this.types});

  factory Camp.fromFirestore(DocumentSnapshot document) {
    Map data = document.data();
    Point<double> location = ((data['location'] ?? GeoPoint(0, 0)) as GeoPoint).toPoint();
    // Fix this when null safety comes to Dart..
    // TODO: hey look, it's 'serialization, the hack'
    final typeStrings = List<String>.from((data['types'] ?? []) as List);
    Set<CampFeature> types = {
      if (typeStrings.contains('tent')) CampFeature.Tent,
      if (typeStrings.contains('hammock')) CampFeature.Hammock,
      if (typeStrings.contains('water')) CampFeature.Water,
    };

    return Camp(
        id: document.id ?? '',
        imageUrls: List<String>.from((data['image_urls'] ?? []) as List),
        location: location,
        score: ((data['score'] ?? 0) as num).toDouble(),
        ratings: data['ratings'] as int ?? 0,
        description: data['description'] as String ?? '',
        creatorId: data['creator_id'] as String ?? '',
        creatorName: data['creator_name'] as String ?? '',
        types: types,);
  }

  Map<String, dynamic> toFirestoreMap() {
    HashMap<String, dynamic> map = HashMap();

    // TODO: Wow such deserialization
    final List<String> typeStrings = [
      if (types.contains(CampFeature.Tent)) 'tent',
      if (types.contains(CampFeature.Hammock)) 'hammock',
      if (types.contains(CampFeature.Water)) 'water',
    ];

    map.addAll({
      'image_urls': imageUrls,  // can't be empty
      'location': location.toGeoPoint(), // can't be empty
      'description': description,  // can't be empty
      'creator_id': creatorId, // can't be empty
      'creator_name': creatorName,  // can't be empty
      'score': score,
      'ratings': ratings,
      'types': typeStrings,
    });
    return map;
  }

  @override
  String toString() {
    return "[Camp ($location $score $ratings $description $imageUrls)]";
  }
}

class CampComment {
  final String commentText;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final DateTime date;
  double score;

  CampComment({@required this.commentText, this.userId, this.userName, this.userPhotoUrl, this.date,
    this.score});

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
    if (data[''] != null) comment.score = data['score'] as double;
    return comment;
  }

  @override
  String toString() => '[CampComment(comment: $commentText, score: $score, user: $userName)]';
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

  @override
  String toString() => '[Favorite($campId)]';
}


