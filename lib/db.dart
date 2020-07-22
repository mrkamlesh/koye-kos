import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'models.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  Stream<List<Camp>> getCampStream() {
    // use ('camps').snapshots for continuous connection with live updates
    return Firestore.instance.collection('camps').snapshots().map(
        (QuerySnapshot snapshot) => snapshot.documents
            .map((DocumentSnapshot document) => Camp.fromFirestore(document))
            .toList());
  }

  Future<Uint8List> getCampImage(String path) {
    return FirebaseStorage.instance.ref().child(path).getData(1000000);
  }

  Future<bool> addCamp(Camp camp, File image) async {
    // Get a reference to new camp
    DocumentReference campRef =
        Firestore.instance.collection('camps').document();

    // Upload images to firestorage, path (camps/camp_id/time_id). Time id can later be used to sort images by upload date
    String imageFileName = DateTime.now().toUtc().toString();
    return FirebaseStorage.instance
        .ref()
        .child('camps/${campRef.documentID}/$imageFileName')
        .putFile(image)
        .onComplete
        .then((value) {
      print('Image upload complete!');
      return true;
    }).catchError((_) {
      print('Error uploading camp!');
      // TODO: do not upload images below
      return false;
    });

    // add image names
    camp.imageUrls.add(imageFileName);
    campRef.setData(camp.toFirestoreMap()).then((value) {
      print('Uploaded camp complete!');
    }).catchError((_) {
      print('Error uploading image!');
      // TODO: delete camp above? notify user that upload failed somehow.
    });
  }

/*  // TODO: business logic to update ratings + score
  Future<void> updateRating(Camp camp) async {
    print(camp.toFirestoreMap());
    // compute new score
    return await Firestore.instance
        .document(camp.id)
        .updateData(camp.toFirestoreMap());
  }*/

  Future<void> deleteCamp(Camp camp) async {
    // compute new score
    return await Firestore.instance
        .collection('camps')
        .document(camp.id)
        .delete();
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
      {favorited = true}) async {
    DocumentReference ref = await Firestore.instance
        .document('camps_favorited/${userId}_${campId}');
    favorited ? ref.setData({}) : ref.delete();
  }
}
