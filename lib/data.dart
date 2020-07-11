import 'package:latlong/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// pojo to camp location, future: add from.json constructor
class Camp {
  final String image_path;
  final LatLng point;
  final double score;
  final int ratings;
  final String description;

  Camp(this.image_path, this.point, this.score, this.ratings, this.description);

  Camp.fromJson(Map<String, dynamic> json)
      : image_path = json['path'],
        point = (json['location'] as GeoPoint).toLatLng(),
        score = json['score'],
        ratings = json['ratings'],
        description = json['description'];

  @override
  String toString() {
    return "[Camp ($point $score $ratings $description ${image_path.substring(0, 10)})]";
  }
}

extension GeoPointLatLngHelper on GeoPoint {
  LatLng toLatLng() => LatLng(this.latitude, this.longitude);
}

void getCamps() {
  Firestore.instance
      .collection('camps')
      .getDocuments()
      .then((QuerySnapshot querySnapshot) => {
            querySnapshot.documents.forEach((document) {
              print(Camp.fromJson(document.data));
            })
          });
}

// Simulate network call to get and build map data
List<Camp> getCampDummy() {
  final String image_path = 'images/spot_1_small.jpg';
  final LatLng campPoint = LatLng(59.813833, 10.412977);
  final LatLng campPoint2 = LatLng(59.833833, 10.402977);
  final double score = 4.7;
  final int ratings = 11;
  final String description = 'This is a description of the camp, looks good!';

  return [
    Camp(image_path, campPoint, score, ratings, description),
    Camp(image_path, campPoint2, score, ratings, description),
  ];
}
