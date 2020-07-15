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
            .map((DocumentSnapshot document) => Camp.fromFirestore(document)));
  }
}
