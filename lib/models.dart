import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:latlong/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Camp {
  final String id;
  final String imageUrl;
  final LatLng location;
  final double score;
  final int ratings;  // save as list of scores?
  final String description;
  final String creatorId;
  final String creatorName;
  // time created?

  Camp(
      {this.id,
        @required this.imageUrl,
        @required this.location,
        this.score,
        this.ratings,
        @required this.description,
        @required this.creatorId,
        @required this.creatorName});

  // TODO: use cache (eg user offline)? otherwise drop factory keyword.
  factory Camp.fromFirestore(DocumentSnapshot document) {
    Map data = document.data;
    LatLng location = (data['location'] as GeoPoint).toLatLng();
    return Camp(
        id: document.documentID,
        imageUrl: data['image_url'],
        location: location,
        score: data['score'] ?? 0,
        ratings: data['ratings'] ?? 0,
        description: data['description'],
        creatorId: data['creator_id'],
        creatorName: data['creator_name']);
  }

  Map<String, dynamic> toFirestoreMap() {
    HashMap<String, dynamic> map = HashMap();
    map.addAll({
      'image_url': imageUrl,
      'location': location.toGeoPoint(),
      'score': score,
      'ratings': ratings,
      'description': description,
      'creator_id': creatorId,
      'creator_name': creatorName
    });
    // TODO: how to do ids
    if (id != null) map['documentID'] = id;
    return map;
  }

  @override
  String toString() {
    return "[Camp ($location $score $ratings $description $imageUrl)]";
  }
}

extension GeoPointLatLngHelper on GeoPoint {
  LatLng toLatLng() => LatLng(latitude, longitude);
}

extension LatLngGeoPointHelper on LatLng {
  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);
}

class User {
  final String id;
  final String name;
  final Set<String> campsCreated;
  final Set<String> campsFavorited;
  final Map<String, int> campsRated;

  User({
    this.id,
    this.name,
    this.campsCreated,
    this.campsFavorited,
    this.campsRated});

  factory User.fromFirestore(DocumentSnapshot document) {
    Map data = document.data;
    return User(
      id: data['id'],
      name: data['name'],
      campsCreated: data['camps_created'],
      campsFavorited: data['camps_favorited'],
      campsRated: data['camps_rated'],
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    HashMap<String, dynamic> map = HashMap();
    map.addAll({
      'id': id,
      'name': name,
      'camps_created': campsCreated?.toList(growable: false),
      'camps_favorited': campsFavorited?.toList(growable: false),
      'camps_rated': campsRated?.entries?.map((e) => {
        'camp': e.key,
        'ranting': e.value,
      })?.toList(growable: false),
    });
    print(map);
    return map;
  }
}


