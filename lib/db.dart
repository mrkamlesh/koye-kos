import 'package:cloud_firestore/cloud_firestore.dart';

import 'data.dart';

class DatabaseService {
  final Firestore _db = Firestore.instance;

  Stream<QuerySnapshot> getCampSnapshot() {
    return _db.collection('camps').snapshots();
  }
}
