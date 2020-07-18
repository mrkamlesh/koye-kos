import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong/latlong.dart';


extension GeoPointHelper on GeoPoint {
  LatLng toLatLng() => LatLng(latitude, longitude);
}

extension LatLngHelper on LatLng {
  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);

  String toReadableString({int precision, String separator}) {
    return latitude.toStringAsFixed(precision) +
        separator +
        longitude.toStringAsFixed(precision);
  }
}