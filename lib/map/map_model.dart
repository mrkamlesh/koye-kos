import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'map_detail.dart';
import '../utils.dart';

enum ClickState {
  None,
  Click,
  LongClick
}

class MapModel extends ChangeNotifier {
  FirestoreService firestore;
  Point<double> longClickCoordinates;
  Point<double> clickCoordinates;
  ClickState _clickState;
  Set<MapSymbolMarker> _campSymbols;
  Stream<Set<MapSymbolMarker>> _campSymbolsStream;
  Map<String, Camp> _campMap;

  MapModel({@required this.firestore}) {
    _clickState = ClickState.None;
    _campSymbolsStream = firestore.getCampListStream().map(_campToSymbolMarker);
  }

  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  ClickState get clickState => _clickState;

  Set<MapSymbolMarker> get campSymbols => _campSymbols;
  Stream<Set<MapSymbolMarker>> get campSymbolsStream => _campSymbolsStream;
  Camp getCamp(String id) => _campMap[id];

  Set<MapSymbolMarker> _campToSymbolMarker(List<Camp> camps) {
    print('_campToSymbolMarker!');
    _campMap = camps.asMap().map((_, camp) => MapEntry(camp.id, camp));
    _campSymbols = camps.map((Camp camp) =>
        MapSymbolMarker(
          options: SymbolOptions(
            geometry: camp.location.toLatLng(),
            iconImage: 'marker-15',
            iconSize: 3,
          ),
          id: camp.id,
        )).toSet();
    notifyListeners();
    return _campSymbols;
  }

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
