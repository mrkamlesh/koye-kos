import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;


import 'package:flutter/material.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/db.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../utils.dart';
import 'map_utils.dart';

enum ClickState { None, Click, LongClick, SymbolClick, DoubleClick }

class MapModel extends ChangeNotifier {
  FirestoreService firestore;

  Set<Camp> _camps;
  Map<String, Camp> _campMap; // camp id to camp
  Set<MapSymbol> _symbols;
  StreamController<Set<MapSymbol>> _symbolStreamController;
  StreamSubscription _campStreamSubscription;

  ClickState _clickState = ClickState
      .Click; // Default to Click such that if user clicks one more time map actions will hide
  Symbol _longClickSymbol;
  bool _trackingMode = false;
  String _mapStyle = MapBoxMapStyle.OUTDOORS;
  Set<CampFeature> _selectedFeatures = {};
  AnimationStatus _animationStatus = AnimationStatus.completed;

  MapModel({@required this.firestore}) {
    _symbolStreamController = StreamController();
    _campStreamSubscription =
        firestore.getCampSetStream().listen(_campToSymbolMarker);
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
  bool get dialVisible => _clickState != ClickState.DoubleClick;
  bool get filterVisible => _clickState != ClickState.DoubleClick;
  bool get tentSelected => _selectedFeatures.contains(CampFeature.Tent);
  bool get hammockSelected => _selectedFeatures.contains(CampFeature.Hammock);
  bool get waterSelected => _selectedFeatures.contains(CampFeature.Water);

  bool get animationNotDismissed =>
      _animationStatus != AnimationStatus.dismissed;
  bool get animationRunningForwardOrComplete =>
      _animationStatus == AnimationStatus.forward ||
      _animationStatus == AnimationStatus.completed;

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
          iconImage: kIsWeb ? 'marker-black' : 'assets/symbols/location_black.png',
          iconSize: 1,
        ),
        id: camp.id,
      );

  void onFeatureSelected(bool selected, CampFeature feature) {
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
      iconImage: kIsWeb ? 'marker-red' : 'assets/symbols/location_red.png',
      iconSize: 1,
    );
  }

  void setLongClickSymbol(Symbol symbol) {
    _longClickSymbol = symbol;
  }

  void onMapClick(LatLng coordinates) {
    _clickState = _clickState == ClickState.Click
        ? ClickState.DoubleClick
        : ClickState.Click;
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

  void onAnimationStatusChange(AnimationStatus status) {
    _animationStatus = status;
    notifyListeners();
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
