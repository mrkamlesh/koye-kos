import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models/camp.dart';
import '../models/user.dart';
import '../utils.dart';
import 'firestore_paths.dart';

class FirestoreService {
  final UserModel user;
  FirestoreService({@required this.user});

  final _firestore = FirebaseFirestore.instance;

  Stream<List<Camp>> getCampListStream() {
    // use ('camps').snapshots for continuous connection with live updates
    return _firestore
        .collection(FirestorePath.campsPath)
        .snapshots()
        .map((QuerySnapshot snapshot) => snapshot.docs
            .map((DocumentSnapshot document) => Camp.fromFirestore(document))
            .toList())
        .handleError((onError, stacktrace) {
      print('Error loading camps! $onError');
      print('Stack:  $stacktrace');
    });
  }

  Future<Uint8List> getCampImage(String path) {
    return FirebaseStorage.instance.ref().child(path).getData(1000000);
  }

  // TODO: adding a camp should be possible to do offline, as many users could be!
  bool addCamp({
    @required String description,
    @required Point<double> location,
    @required List<File> images,
  }) {
    // Get a reference to new camp
    DocumentReference campRef =
        _firestore.collection(FirestorePath.campsPath).doc();

    // Write location data immediately, such that the camp location shows up on screen.
    campRef.set(<String, dynamic>{
      'location': location.toGeoPoint(),
      'description': description,
    });

    // Start long running compression and uploading. TODO: handle no internet connection.
    _uploadInBackground(
      campRef: campRef,
      description: description,
      location: location,
      images: images,
    );
    return true;
  }

  Future<void> _uploadInBackground({
    @required DocumentReference campRef,
    @required String description,
    @required Point<double> location,
    @required List<File> images,
  }) async {
    // Compress images
    List<Uint8List> imagesCompressed =
        await Future.wait(images.map((File image) async {
      return await FlutterImageCompress.compressWithFile(image.path,
          quality: 60, minWidth: 2000, minHeight: 1500);
    }));

    StorageReference campImagesRef = FirebaseStorage.instance
        .ref()
        .child(FirestoragePath.getCampImagesPath(campRef.id));

    final imageUrls = <String>[];

    // Upload images to firestorage, path (camps/camp_id/time_id). Time id can later be used to sort images by upload date
    await Future.forEach(imagesCompressed, ((Uint8List imageList) async {
      String imageName = DateTime.now().toUtc().toString();
      await campImagesRef
          .child('$imageName')
          .putData(imageList)
          .onComplete
          .then((value) async {
        print('Image upload complete!');
        await value.ref.getDownloadURL().then((value) {
          imageUrls.add(value.toString());
        });
      }).catchError((_) {
        print('Error uploading camp!');
        // TODO: properly handle upload failed (delete images, cancel transaction..).
        return false;
      });
    }));

    // add image names
    Camp camp = Camp(
        id: campRef.id,
        imageUrls: imageUrls,
        location: location,
        description: description,
        creatorId: user.id,
        creatorName: user.name);

    campRef.set(camp.toFirestoreMap(), SetOptions(merge: true)).then((value) {
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
  Future<void> updateRating(
      {@required String campId,
      @required double score,
      bool delete = false}) async {
    // compute new score
    final DocumentReference campRef =
        _firestore.collection(FirestorePath.campsPath).doc(campId);

    final DocumentReference userRatingRef =
        campRef.collection(FirestorePath.ratingsPath).doc(user.id);

    return _firestore.runTransaction((Transaction transaction) async {
      DocumentSnapshot campSnapshot = await transaction.get(campRef);
      if (campSnapshot.exists) {
        // Get current camp scores
        int currentRatings = campSnapshot.get('ratings') as int;
        // Total cumulative rating
        double currentTotalScore =
            (campSnapshot.get('score') as num).toDouble() * currentRatings;

        // Check if user already rated this camp
        await userRatingRef.get().then((snapshot) {
          if (snapshot.exists) {
            // Revert users current score
            currentTotalScore -= (snapshot.get('score') as num).toDouble();
            currentRatings -= 1;
          }
        });
        if (delete) {
          userRatingRef.delete(); // delete users score
          // set score where this user's score is removed
          return transaction.update(campRef, <String, dynamic>{
            'ratings': currentRatings,
            'score': currentTotalScore
          });
        } else {
          // Set users new score
          userRatingRef.set({'score': score});

          // Calculate new camp score
          int newRatings = currentRatings + 1;
          double newScore = (currentTotalScore + score) / newRatings;

          return transaction.update(campRef,
              <String, dynamic>{'ratings': newRatings, 'score': newScore});
        }
      }
    });
  }

  Future<void> deleteCampComment({@required String campId}) {
    return _firestore
        .collection(FirestorePath.getCommentsPath(campId))
        .doc(user.id)
        .delete();
  }

  Future<void> addCampComment(
      {@required String campId, @required String comment, double score}) {
    Map<String, dynamic> data = {
      'comment': comment,
      'user_name': user.name,
      'user_id': user.id,
      'user_photo_url': user.photoUrl,
      'date': Timestamp.now(),
    };
    if (score != null) data['score'] = score;

    return _firestore
        .collection(FirestorePath.getCommentsPath(campId))
        .doc(user.id)
        .set(data);
  }

  Stream<List<CampComment>> getCommentsStream(String campId) {
    return _firestore
        .collection(FirestorePath.getCommentsPath(campId))
        .snapshots()
        .map((QuerySnapshot snapshot) => snapshot.docs)
        .map((List<DocumentSnapshot> documents) => documents
            .map((DocumentSnapshot document) =>
                CampComment.fromFirestore(document))
            .toList());
  }

  Future<double> getCampRating(String campId) {
    return _firestore
        .collection(FirestorePath.getRatingPath(campId))
        .doc(user.id)
        .get()
        .then((DocumentSnapshot snapshot) {
      return snapshot.exists ? (snapshot.get('score') as num).toDouble() : 0;
    });
  }

  Stream<Camp> getCampStream(String campId) {
    return _firestore
        .collection(FirestorePath.campsPath)
        .doc(campId)
        .snapshots()
        .map((DocumentSnapshot snapshot) {
      return Camp.fromFirestore(snapshot);
    });
  }

  Stream<List<Camp>> getCampsStream(List<String> campIds) {
    return _firestore
        .collection(FirestorePath.campsPath)
        .where('__name__', whereIn: campIds)
        .snapshots()
        .map((QuerySnapshot event) => event.docs)
        .map((List<DocumentSnapshot> e) =>
            e.map((DocumentSnapshot e) => Camp.fromFirestore(e)).toList());
  }

  Future<void> deleteCamp(String campId) async {
    // compute new score
    _firestore.collection(FirestorePath.campsPath).doc(campId).delete();

    /*
    Firebase storage does not support client side deletion of buckets..
    TODO: use cloud function to delete folder, triggered on camp deletion.
    FirebaseStorage.instance
        .ref()
        .child('camps/${camp.id}/')
        .delete();*/
  }

  Stream<bool> getCampFavoritedStream(String campId) {
    return _firestore
        .collection(FirestorePath.getFavoritePath(user.id))
        .doc(campId)
        .snapshots()
        .map((DocumentSnapshot documentSnapshot) => documentSnapshot.exists);
  }

  Stream<List<Favorite>> campIdsFavoritedStream() {
    return _firestore
        .collection(FirestorePath.getFavoritePath(user.id))
        .orderBy('time', descending: true)
        .snapshots()
        .map((QuerySnapshot snapshot) => snapshot.docs
            .map(
                (DocumentSnapshot document) => Favorite.fromFirestore(document))
            .toList());
  }

  Stream<List<Camp>> campsFavoritedStream() async* {
    List<String> ids = await _firestore
        .collection(FirestorePath.getFavoritePath(user.id))
        .get()
        .then((QuerySnapshot snapshot) =>
            snapshot.docs.map((e) => e.id).toList());
    yield* _firestore
        .collection(FirestorePath.campsPath)
        .where('__name__', whereIn: ids)
        .snapshots()
        .map((QuerySnapshot snapshot) => snapshot.docs
            .map((DocumentSnapshot document) => Camp.fromFirestore(document))
            .toList());
  }

  Future<void> setFavorited(String campId, {bool favorited = true}) async {
    if (favorited) {}
    DocumentReference ref = await _firestore
        .collection(FirestorePath.getFavoritePath(user.id))
        .doc(campId);

    favorited
        ? ref.set(<String, dynamic>{'time': FieldValue.serverTimestamp()})
        : ref.delete();
  }

  Future<void> addUser(UserModel userModel) async {
    return _firestore
        .collection(FirestorePath.usersPath)
        .doc(user.id)
        .set(userModel.toFirestoreMap());
  }

  Stream<UserModel> getUserStream() {
    return _firestore
        .collection(FirestorePath.usersPath)
        .doc(user.id)
        .snapshots()
        .map((DocumentSnapshot document) => UserModel.fromFirestore(document));
  }
}
