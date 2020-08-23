import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_gl/mapbox_gl.dart';


extension GeoPointHelper on GeoPoint {
  LatLng toLatLngPoint() => LatLng(latitude, longitude);
  Point<double> toPoint() => Point(latitude, longitude);
}

extension PointHelper on Point {
  GeoPoint toGeoPoint() => GeoPoint(x.toDouble(), y.toDouble());
  LatLng toLatLng() => LatLng(x.toDouble(), y.toDouble());

  String toReadableString({int precision, String separator}) {
    return x.toStringAsFixed(precision) +
        separator +
        y.toStringAsFixed(precision);
  }
}

extension LatLngHelper on LatLng {
  Point<double> toPoint() => Point(latitude, longitude);

}