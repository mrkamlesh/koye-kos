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

  // TODO: adding a camp should be possible to do offline, as many users could be!
  Future<bool> addCamp(Camp camp, List<File> images) async {
    // Get a reference to new camp
    DocumentReference campRef =
    Firestore.instance.collection('camps').document();

    StorageReference imageStoreRef = FirebaseStorage.instance
        .ref()
        .child('camps/${campRef.documentID}/');
    final imageNames = <String>[];
    // Upload images to firestorage, path (camps/camp_id/time_id). Time id can later be used to sort images by upload date
    images.forEach((File image) {
      String imageName = DateTime.now().toUtc().toString();
      imageNames.add(imageName);
      imageStoreRef
          .child('$imageName')
          .putFile(image)
          .onComplete
          .then((value) {
        print('Image upload complete!');
      }).catchError((_) {
        print('Error uploading camp!');
        // TODO: Revert uploads (?), notify user
        return false;
      });
    });

    // add image names
    camp.imageUrls.addAll(imageNames);
    return campRef.setData(camp.toFirestoreMap()).then((value) {
      print('Uploaded camp complete!');
      return true;
    }).catchError((_) {
      print('Error uploading image!');
      // TODO: handle upload failed
      return false;
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
