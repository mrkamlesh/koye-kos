import 'package:latlong/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Camp {
  final String imageUrl;
  final LatLng location;
  final double score;
  final int ratings;
  final String description;

  Camp(
      {this.imageUrl,
      this.location,
      this.score,
      this.ratings,
      this.description});

  // TODO: use cache (eg user offline)? otherwise drop factory keyword.
  factory Camp.fromFirestore(DocumentSnapshot docuemnt) {
    Map data = docuemnt.data;
    LatLng location = (data['location'] as GeoPoint).toLatLng();
    return Camp(
        imageUrl: data['image_url'],
        location: location,
        score: data['score'],
        ratings: data['ratings'],
        description: data['description']);
  }

  @override
  String toString() {
    return "[Camp ($location $score $ratings $description $imageUrl)]";
  }
}

extension GeoPointLatLngHelper on GeoPoint {
  LatLng toLatLng() => LatLng(this.latitude, this.longitude);
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
    /*Camp(image_path, campPoint, score, ratings, description),
    Camp(image_path, campPoint2, score, ratings, description),*/
  ];
}
