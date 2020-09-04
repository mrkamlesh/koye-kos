
import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String campId;
  final Timestamp time;

  Favorite({this.campId, this.time});

  factory Favorite.fromFirestore(DocumentSnapshot document) {
    return Favorite(
        campId: document.id,
        time: document.data()['time'] as Timestamp);
  }

  @override
  String toString() => '[Favorite($campId)]';
}