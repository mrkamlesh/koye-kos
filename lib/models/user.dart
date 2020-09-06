import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String id;
  String name;
  String email;
  String photoUrl;
  Set<String> campsCreated;
  Set<String> favorited;
  Map<String, int> campsRated;
  Set<String> commentsReported;
  auth.User firebaseUser;  // TODO: is the duplicating user info needed?

  UserModel({
    this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.campsCreated,
    this.favorited,
    this.campsRated,
    this.commentsReported});

  void setFirebaseUser(auth.User user) {
    this.firebaseUser = user;
    this.id = user.uid;
    this.name = user.displayName;
    this.email = user.email;
    this.photoUrl = user.photoUrl;
  }

  factory UserModel.fromFirestore(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data();
    print(data);
    return UserModel(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      photoUrl: data['photo_url'] as String,

      commentsReported: List<String>.from((data['comments_reported'] ?? []) as List).toSet()
      //campsCreated: data['camps_created'],
      //favorited: data['favorited'],
      //campsRated: data['camps_rated'],
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    HashMap<String, dynamic> map = HashMap();
    map.addAll({
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      //'camps_created': campsCreated,
/*      'camps_rated': campsRated?.entries?.map((e) => {
        'camp': e.key,
        'ranting': e.value,})?.toList(growable: false),*/
    });
    return map;
  }

  @override
  String toString() {
    return 'User [id: ${this.id} name: ${this.name}]';
  }
}