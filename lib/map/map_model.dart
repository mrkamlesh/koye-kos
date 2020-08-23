import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'map_detail.dart';
import '../utils.dart';

enum ClickState {
  None,
  Click,
  LongClick
}

class MapModel extends ChangeNotifier {
  Point<double> longClickCoordinates;
  Point<double> clickCoordinates;
  ClickState _clickState;

  MapModel() {
    _clickState = ClickState.None;
  }

  ClickState get clickState => _clickState;

  void onMapLongClick(LatLng coordinates) {
    longClickCoordinates = coordinates.toPoint();
    _clickState = ClickState.LongClick;
    notifyListeners();
  }

  void onMapClick(LatLng coordinates) {
    clickCoordinates = coordinates.toPoint();
    _clickState = ClickState.Click;
    notifyListeners();
  }
}
