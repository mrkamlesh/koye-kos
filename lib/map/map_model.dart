import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'map_detail.dart';
import '../utils.dart';

enum ClickState { None, Click, LongClick, SymbolClick }

enum MapStyle { Outdoors, Satellite }

class MapBoxMapStyle {
  static const OUTDOORS = MapboxStyles.OUTDOORS;
  static const SATELLITE = MapboxStyles.SATELLITE;
  
  static String getMapStyle(MapStyle style) {
    switch(style) {
      case MapStyle.Outdoors: return OUTDOORS;
      case MapStyle.Satellite: return SATELLITE;
      default: return OUTDOORS;
    }
  }
}

class MapModel extends ChangeNotifier {
  FirestoreService firestore;
  Point<double> longClickCoordinates;
  Point<double> clickCoordinates;
  ClickState _clickState;
  Set<MapSymbolMarker> _campSymbols;
  Stream<Set<MapSymbolMarker>> _campSymbolsStream;
  Map<String, Camp> _campMap;
  Symbol _longClickSymbol;
  bool _locationTracking = false;
  String _styleString = MapBoxMapStyle.OUTDOORS;

  MapModel({@required this.firestore}) {
    _clickState = ClickState.None;
    _campSymbolsStream = firestore.getCampListStream().map(_campToSymbolMarker);
  }
  
  void onStyleSelected(MapStyle style) {
    _styleString = MapBoxMapStyle.getMapStyle(style);
    notifyListeners();
  }

  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  ClickState get clickState => _clickState;

  Stream<Set<MapSymbolMarker>> get campSymbolsStream => _campSymbolsStream;
  Camp getCamp(String id) => _campMap[id];

  bool get locationTracking => _locationTracking;

  MyLocationTrackingMode get trackingMode => _locationTracking
      ? MyLocationTrackingMode.Tracking
      : MyLocationTrackingMode.None;

  String get mapStyle => _styleString;

  Set<MapSymbolMarker> _campToSymbolMarker(List<Camp> camps) {
    _campMap = camps.asMap().map((_, camp) => MapEntry(camp.id, camp));
    _campSymbols = camps
        .map((Camp camp) => MapSymbolMarker(
      options: SymbolOptions(
        geometry: camp.location.toLatLng(),
        iconImage: 'marker-15',
        iconSize: 3,
      ),
      id: camp.id,
    ))
        .toSet();
    return _campSymbols;
  }

  SymbolOptions onMapLongClick(LatLng coordinates) {
    longClickCoordinates = coordinates.toPoint();
    _clickState = ClickState.LongClick;
    notifyListeners();
    return SymbolOptions(
      geometry: coordinates,
      iconImage: 'marker-15',
      iconSize: 4,
    );
  }

  void setLongClickSymbol(Symbol symbol) {
    _longClickSymbol = symbol;
  }

  Symbol get longCLickSymbol => _longClickSymbol;

  void onMapClick(LatLng coordinates) {
    clickCoordinates = coordinates.toPoint();
    _clickState = ClickState.Click;
    _longClickSymbol = null;
    notifyListeners();
  }

  void onSymbolTapped() {
    _clickState = ClickState.SymbolClick;
    notifyListeners();
  }

  void onGpsClick() async {
    final location = Location();
    final hasPermissions = await location.hasPermission();
    if (hasPermissions == PermissionStatus.granted) _toggleLocationTracking();
    else {
      final PermissionStatus status = await location.requestPermission();
      if (status == PermissionStatus.granted) _toggleLocationTracking();
    }
  }

  void _toggleLocationTracking() {
    _locationTracking = !_locationTracking;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class MapSymbolMarker {
  final SymbolOptions options;
  final String id;
  MapSymbolMarker({this.options, this.id});
}
