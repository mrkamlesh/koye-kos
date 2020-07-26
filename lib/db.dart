import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';

import 'models.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  Stream<List<Camp>> getCampListStream() {
    // use ('camps').snapshots for continuous connection with live updates
    return Firestore.instance
        .collection('camps')
        .snapshots()
        .map((QuerySnapshot snapshot) => snapshot.documents
        .map((DocumentSnapshot document) => Camp.fromFirestore(document))
        .toList())
        .handleError((onError) {
      print('Error loading camps! $onError');
    });
  }

  Future<Uint8List> getCampImage(String path) {
    return FirebaseStorage.instance.ref().child(path).getData(1000000);
  }

  // TODO: adding a camp should be possible to do offline, as many users could be!
  Future<bool> addCamp(
      {@required String description,
        @required LatLng location,
        @required String creatorId,
        @required String creatorName,
        @required List<File> images}) async {
    // TODO: store paths in a static class
    // Get a reference to new camp
    DocumentReference campRef =
    Firestore.instance.collection('camps').document();
    String imagesStorePath = 'camps/${campRef.documentID}';
    StorageReference imageStoreRef =
    FirebaseStorage.instance.ref().child(imagesStorePath);
    final imageUrls = <String>[];

    // Upload images to firestorage, path (camps/camp_id/time_id). Time id can later be used to sort images by upload date
    await Future.forEach(images, ((File image) async {
      String imageName = DateTime.now().toUtc().toString();
      await imageStoreRef
          .child('$imageName')
          .putFile(image)
          .onComplete
          .then((value) async {
        print('Image upload complete!');
        await value.ref.getDownloadURL().then((value) {
          imageUrls.add(value.toString());
        });
      }).catchError((_) {
        print('Error uploading camp!');
        campRef.delete();
        imageStoreRef.delete();
        return false;
      });
    }));

    // add image names
    Camp camp = Camp(
        id: campRef.documentID,
        imageUrls: imageUrls,
        location: location,
        description: description,
        creatorId: creatorId,
        creatorName: creatorName);
    return campRef.setData(camp.toFirestoreMap()).then((value) {
      print('Uploaded camp complete!');
      return true;
    }).catchError((_) {
      print('Error uploading image!');
      // TODO: handle upload failed
      return false;
    });
  }

  // Subject to this: https://github.com/FirebaseExtended/flutterfire/issues/1969
  // Possible circumvention: do nout use await in transaction code
  Future<void> updateRating(Camp camp, FirebaseUser user, double score) async {
    // compute new score
    final DocumentReference campRef =
    Firestore.instance.collection('camps').document(camp.id);

    final DocumentReference userRatingRef =
    campRef.collection('user_ratings').document('${user.uid}_${camp.id}');

    return Firestore.instance.runTransaction((Transaction transaction) async {
      DocumentSnapshot campSnapshot = await transaction.get(campRef);
      if (campSnapshot.exists) {
        // Get current camp scores
        int currentRatings = campSnapshot.data['ratings'] as int;
        // Total cumulative rating
        double currentTotalScore =
            (campSnapshot.data['score'] as num).toDouble() * currentRatings;

        // Check if user already rated this camp
        await userRatingRef.get().then((snapshot) {
          if (snapshot.exists) {
            // Revert users current score
            currentTotalScore -= (snapshot.data['score'] as num).toDouble();
            currentRatings -= 1;
          }
        });

        // Set users new score
        userRatingRef.setData({'score': score});

        // Calculate new camp score
        int newRatings = currentRatings + 1;
        double newScore = (currentTotalScore + score) / newRatings;

        return transaction.update(campRef,
            <String, dynamic>{'ratings': newRatings, 'score': newScore});
      }
    });
  }

  Stream<Camp> getCampStream(String campId) {
    return Firestore.instance
        .collection('camps')
        .document(campId)
        .snapshots()
        .map((DocumentSnapshot snapshot) {
      return Camp.fromFirestore(snapshot);
    });
  }

  Future<void> deleteCamp(Camp camp) async {
    print('Delete: ${camp.id}');
    // compute new score
    Firestore.instance.collection('camps').document(camp.id).delete();

    /*
    Firebase storage does not support client side deletion of buckets..
    TODO: use cloud function to delete folder, triggered on camp deletion.
    FirebaseStorage.instance
        .ref()
        .child('camps/${camp.id}/')
        .delete();*/
  }

/*  Future<void> addUser(User user) async {
    return await Firestore.instance
        .collection('users')
        .add(user.toFirestoreMap());
  }*/

  Stream<bool> campFavoritedStream(String userId, String campId) {
    return Firestore.instance
        .collection('camps_favorited')
        .document('${userId}_${campId}')
        .snapshots()
        .map((DocumentSnapshot documentSnapshot) => documentSnapshot.exists);
  }

  Future<void> setFavorited(String userId, String campId,
      {bool favorited = true}) async {
    DocumentReference ref = await Firestore.instance
        .document('camps_favorited/${userId}_${campId}');
    favorited ? ref.setData({}) : ref.delete();
  }
}
