import 'package:latlong/latlong.dart';


// pojo to camp location, future: add from.json constructor
class CampLocation {
  final String image_path;
  final LatLng point;
  final double score;
  final int ratings;
  final String description;

  CampLocation(this.image_path, this.point, this.score, this.ratings, this.description);
}

// Simulate network call to get and build map data
List<CampLocation> getCampLocations() {
  final String image_path = 'images/spot_1.jpg';
  final LatLng campPoint = LatLng(59.813833, 10.412977);
  final LatLng campPoint2 = LatLng(59.833833, 10.402977);
  final double score = 4.7;
  final int ratings = 11;
  final String description = 'This is a description of the camp, looks good!';

  return [
    CampLocation(
        image_path,
        campPoint,
        score,
        ratings,
        description
    ),
    CampLocation(
        image_path,
        campPoint2,
        score,
        ratings,
        description
    ),
  ];
}
