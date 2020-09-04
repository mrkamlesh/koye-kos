import 'dart:async';

import 'package:flutter/material.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/db.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../utils.dart';

enum ClickState { None, Click, LongClick, SymbolClick }

enum MapStyle { Outdoors, Satellite }

class MapBoxMapStyle {
  static const OUTDOORS =
      'mapbox://styles/samudev/ckdxjbopx44gj1aorm1eumxo6'; /*MapboxStyles.OUTDOORS;*/
  static const SATELLITE = MapboxStyles.SATELLITE;

  static String getMapStyle(MapStyle style) {
    switch (style) {
      case MapStyle.Outdoors:
        return OUTDOORS;
      case MapStyle.Satellite:
        return SATELLITE;
      default:
        return OUTDOORS;
    }
  }
}

class MapModel extends ChangeNotifier {
  FirestoreService firestore;

  Set<Camp> _camps;
  Map<String, Camp> _campMap; // camp id to camp
  Set<MapSymbol> _symbols;
  StreamController<Set<MapSymbol>> _symbolStreamController;
  StreamSubscription _campStreamSubscription;

  ClickState _clickState;
  Symbol _longClickSymbol;
  bool _trackingMode = false;
  String _mapStyle = MapBoxMapStyle.OUTDOORS;
  bool _dialVisible = true;
  Set<CampFeature> _selectedFeatures = {};

  MapModel({@required this.firestore}) {
    _clickState = ClickState.None;
    _symbolStreamController = StreamController();
    _campStreamSubscription = firestore.getCampSetStream().listen(_campToSymbolMarker);
  }

  void onStyleSelected(MapStyle style) {
    _mapStyle = MapBoxMapStyle.getMapStyle(style);
    notifyListeners();
  }

  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  Stream<Set<MapSymbol>> get campSymbolStream => _symbolStreamController.stream;
  Set<MapSymbol> get campSymbolSet => _symbols;
  Camp getCamp(String id) => _campMap[id];

  ClickState get clickState => _clickState;
  Symbol get longCLickSymbol => _longClickSymbol;

  bool get locationTracking => _trackingMode;
  MyLocationTrackingMode get trackingMode => _trackingMode
      ? MyLocationTrackingMode.Tracking
      : MyLocationTrackingMode.None;

  String get mapStyle => _mapStyle;
  bool get dialVisible => _dialVisible;
  bool get tentSelected => _selectedFeatures.contains(CampFeature.Tent);
  bool get hammockSelcted => _selectedFeatures.contains(CampFeature.Hammock);
  bool get waterSelcted => _selectedFeatures.contains(CampFeature.Water);

  Set<MapSymbol> _campToSymbolMarker(Set<Camp> camps) {
    _camps = camps.toSet();
    _campMap = Map.fromEntries(camps.map((camp) => MapEntry(camp.id, camp)));
    _symbols = camps.map(_campToMapSymbol).toSet();
    _symbolStreamController.add(_symbols);
    return _symbols;
  }

  MapSymbol _campToMapSymbol(Camp camp) => MapSymbol(
        options: SymbolOptions(
          geometry: camp.location.toLatLng(),
          iconImage: 'assets/symbols/location_black.png',
          iconSize: 1,
        ),
        id: camp.id,
      );

  void onFilterChipSelected(bool selected, CampFeature feature) {
    selected
        ? _selectedFeatures.add(feature)
        : _selectedFeatures.remove(feature);
    _symbols = _selectedFeatures.isNotEmpty
        ? _camps
            .where((camp) => camp.features.contains(feature))
            .map(_campToMapSymbol)
            .toSet()
        : _camps.map(_campToMapSymbol).toSet();
    _symbolStreamController.add(_symbols);
    notifyListeners();
  }

  SymbolOptions onMapLongClick(LatLng coordinates) {
    _clickState = ClickState.LongClick;
    notifyListeners();
    return SymbolOptions(
      geometry: coordinates,
      iconImage: 'assets/symbols/location_red.png',
      iconSize: 1,
    );
  }

  void setLongClickSymbol(Symbol symbol) {
    _longClickSymbol = symbol;
  }

  void onMapClick(LatLng coordinates) {
    if (_clickState == ClickState.Click) {
      _dialVisible = !_dialVisible;
    }
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
    if (hasPermissions == PermissionStatus.granted)
      _toggleLocationTracking();
    else {
      final PermissionStatus status = await location.requestPermission();
      if (status == PermissionStatus.granted) _toggleLocationTracking();
    }
  }

  void _toggleLocationTracking() {
    _trackingMode = !_trackingMode;
    notifyListeners();
  }

  @override
  void dispose() {
    _campStreamSubscription.cancel();
    _symbolStreamController.close();
    super.dispose();
  }
}

class MapSymbol {
  final SymbolOptions options;
  final String id;
  MapSymbol({this.options, this.id});
}
