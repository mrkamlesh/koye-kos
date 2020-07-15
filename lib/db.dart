import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final Firestore _db = Firestore.instance;

  Stream<QuerySnapshot> getCampSnapshot() {
    // use ('camps').snapshots for continuous connection with live updates
    return _db.collection('camps').getDocuments().asStream();
  }
}
