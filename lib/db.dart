import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:koye_kos/map.dart';

import 'models.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  Future<List<CampMarker>> getCampMarkerFuture() {
    // use ('camps').snapshots for continuous connection with live updates
    return Firestore.instance.collection('camps').getDocuments().then(
        (QuerySnapshot query) => query.documents
            .map((DocumentSnapshot document) => Camp.fromFirestore(document))
            .map((Camp camp) => CampMarker(camp))
            .toList());
  }

  Stream<List<Camp>> getCampStream() {
    // use ('camps').snapshots for continuous connection with live updates
    return Firestore.instance.collection('camps').snapshots().map(
        (QuerySnapshot snapshot) => snapshot.documents
            .map((DocumentSnapshot document) => Camp.fromFirestore(document))
            .toList());
  }

  Stream<List<CampMarker>> getCampMarkerStream() {
    // use ('camps').snapshots for continuous connection with live updates
    return Firestore.instance.collection('camps').snapshots().map(
            (QuerySnapshot snapshot) => snapshot.documents
            .map((DocumentSnapshot document) => Camp.fromFirestore(document))
            .map((Camp camp) => CampMarker(camp))
            .toList());
  }

  Future<void> addCamp(Camp camp) async {
    print('addCamp ${camp.toFirestoreMap()}');
    return await Firestore.instance
        .collection('camps')
        .add(camp.toFirestoreMap());
  }

  // TODO: business logic to update ratings + score
  Future<void> updateRating(Camp camp) async {
    print(camp.toFirestoreMap());
    // compute new score
    return await Firestore.instance
        .document(camp.id)
        .updateData(camp.toFirestoreMap());
  }
}
