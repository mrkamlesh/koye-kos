import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:latlong/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils.dart';

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
    Map data = document.data;
    LatLng location = (data['location'] as GeoPoint).toLatLng();
    return Camp(
        id: document.documentID,
        imageUrls: List<String>.from(data['image_urls'] as List),
        location: location,
        score: (data['score'] as num).toDouble(),
        ratings: data['ratings'] as int,
        description: data['description'] as String,
        creatorId: data['creator_id'] as String,
        creatorName: data['creator_name'] as String);
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

class User {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final Set<String> campsCreated;
  final Set<String> campsFavorited;
  final Map<String, int> campsRated;

  User({
    this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.campsCreated,
    this.campsFavorited,
    this.campsRated});

  factory User.fromFirestore(DocumentSnapshot document) {
    Map data = document.data;
    return User(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      photoUrl: data['photo_url'] as String,
      //campsCreated: data['camps_created'],
      campsFavorited: data['camps_favorited'],
      //campsRated: data['camps_rated'],
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    HashMap<String, dynamic> map = HashMap();
    map.addAll({
      'id': id,
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      //'camps_created': campsCreated,
      'camps_favorited': campsFavorited,
/*      'camps_rated': campsRated?.entries?.map((e) => {
        'camp': e.key,
        'ranting': e.value,})?.toList(growable: false),*/
    });
    print(map);
    return map;
  }
}


