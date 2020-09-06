import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:koye_kos/models/comment.dart';
import 'package:koye_kos/models/favorite.dart';

import '../models/camp.dart';
import '../models/user.dart';
import '../utils.dart';
import 'firestore_paths.dart';

class FirestoreService {
  final UserModel user;
  FirestoreService({@required this.user});

  final _firestore = FirebaseFirestore.instance;

  // Camp --------------

  Stream<Set<Camp>> getCampSetStream() {
    return _firestore
        .collection(FirestorePath.campsPath)
        .snapshots()
        .map((QuerySnapshot snapshot) => snapshot.docs
            .map((DocumentSnapshot document) => Camp.fromFirestore(document))
            .toSet())
        .handleError((onError, stacktrace) {
      print('Error loading camps! $onError');
      print('Stack:  $stacktrace');
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

  Future<Uint8List> getCampImage(String path) {
    return FirebaseStorage.instance.ref().child(path).getData(1000000);
  }

  Stream<List<Camp>> getCampsFromIdsStream(List<String> campIds) {
    return _firestore
        .collection(FirestorePath.campsPath)
        .where('__name__', whereIn: campIds)
        .snapshots()
        .map((QuerySnapshot event) => event.docs)
        .map((List<DocumentSnapshot> e) =>
            e.map((DocumentSnapshot e) => Camp.fromFirestore(e)).toList());
  }

  // TODO: adding a camp should be possible to do offline, as many users could be!
  bool addCamp({
    @required String description,
    @required Point<double> location,
    @required List<File> images,
    @required Set<CampFeature> types,
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
      types: types,
    );
    return true;
  }

  Future<void> _uploadInBackground(
      {@required DocumentReference campRef,
      @required String description,
      @required Point<double> location,
      @required List<File> images,
      @required Set<CampFeature> types}) async {
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
        creatorName: user.name,
        features: types);

    campRef.set(camp.toFirestoreMap(), SetOptions(merge: true)).then((value) {
      print('Uploaded camp complete!');
      return true;
    }).catchError((error) {
      print('Error uploading image! $error');
      // TODO: handle upload failed
      return false;
    });
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

  Future<void> updateRating({
    @required String campId,
    @required double score,
  }) {
    return _firestore
        .collection(FirestorePath.getRatingPath(campId))
        .doc(user.id)
        .set({'score': score});
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

  // Comment -----------

  Future<void> addComment(
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

  Future<void> deleteComment({@required String campId}) {
    return _firestore
        .collection(FirestorePath.getCommentsPath(campId))
        .doc(user.id)
        .delete();
  }

  Future<void> reportComment({@required String campId, @required String commentId}) {
    print('add');

    _firestore
    .collection(FirestorePath.usersPath)
    .doc(user.id)
    .update({'comments_reported': FieldValue.arrayUnion([commentId])});

    return _firestore
        .collection(FirestorePath.getCommentReportPath(campId, commentId))
        .doc(user.id)
        .set({});
  }

  Future<void> reportCommentRemove({@required String campId, @required String commentId}) {
    print('remove');
    _firestore
        .collection(FirestorePath.usersPath)
        .doc(user.id)
        .update({'comments_reported': FieldValue.arrayRemove([commentId])});

    return _firestore
        .collection(FirestorePath.getCommentReportPath(campId, commentId))
        .doc(user.id)
        .delete();
  }

  // User -> camp ------

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

  Future<void> setFavorited(String campId, {bool favorited = true}) async {
    if (favorited) {}
    DocumentReference ref = await _firestore
        .collection(FirestorePath.getFavoritePath(user.id))
        .doc(campId);

    favorited
        ? ref.set(<String, dynamic>{'time': FieldValue.serverTimestamp()})
        : ref.delete();
  }
}

class FirestoreUtils {
  static final _firestore = FirebaseFirestore.instance;

  // User --------------
  static Future<void> addUser(User user) async {
    final UserModel userModel = UserModel(
      id: user.uid,
      name: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );

    return _firestore
        .collection(FirestorePath.usersPath)
        .doc(user.uid)
        .set(userModel.toFirestoreMap(), SetOptions(merge: true));
  }

  static Stream<UserModel> getUserStream(String userId) {
    return _firestore
        .collection(FirestorePath.usersPath)
        .doc(userId)
        .snapshots()
        .map((DocumentSnapshot document) => UserModel.fromFirestore(document));
  }

}