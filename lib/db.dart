import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:koye_kos/map.dart';

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

/*  Stream<List<CampMarker>> getCampMarkerStream() {
    // use ('camps').snapshots for continuous connection with live updates
    return Firestore.instance.collection('camps').snapshots().map(
            (QuerySnapshot snapshot) => snapshot.documents
            .map((DocumentSnapshot document) => Camp.fromFirestore(document))
            .map((Camp camp) => CampMarker(camp))
            .toList());
  }*/

  Future<void> addCamp(Camp camp) async {
    return await Firestore.instance
        .collection('camps')
        .add(camp.toFirestoreMap());
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

  Future<void> setFavorited(String userId, String campId, {favorited = true}) async {
    DocumentReference ref = await Firestore.instance
        .document('camps_favorited/${userId}_${campId}');
    favorited ? ref.setData({}) : ref.delete();
  }

}
