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
  Set<String> imagesReported;
  auth.User firebaseUser;  // TODO: is the duplicating user info needed?

  UserModel({
    this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.campsCreated,
    this.favorited,
    this.campsRated,
    this.commentsReported,
    this.imagesReported,
  });

  void setFirebaseUser(auth.User user) {
    this.firebaseUser = user;
    this.id = user.uid;
    this.name = user.displayName;
    this.email = user.email;
    this.photoUrl = user.photoUrl;
  }

  factory UserModel.fromFirestore(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data();
    return UserModel(
      id: document.id,
      name: data['name'] as String,
      email: data['email'] as String,
      photoUrl: data['photo_url'] as String,
      commentsReported: List<String>.from((data['comments_reported'] ?? []) as List).toSet(),
      imagesReported: List<String>.from((data['images_reported'] ?? []) as List).toSet(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    HashMap<String, dynamic> map = HashMap();
    map.addAll({
      'name': name,
      'email': email,
      'photo_url': photoUrl,
    });
    return map;
  }

  @override
  String toString() {
    return 'User [id: ${this.id} name: ${this.name}]';
  }
}