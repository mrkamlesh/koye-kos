import 'dart:async';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/camp/camp_utils.dart';
import 'package:koye_kos/map/map_detail.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/services/db.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

import 'map_model.dart';
import '../utils.dart';

class Map extends StatefulWidget {
  @override
  State createState() => MapState();
}

class MapState extends State<Map> {
  MapboxMapController _mapController;
  StreamSubscription _symbolsSubscription;

  @override
  Widget build(BuildContext context) {
    //print('-build');

    return Consumer<MapModel>(
      builder: (context, mapModel, _) {
        //print('-consumer!');
        return Scaffold(
          body: MapboxMap(
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition:
            const CameraPosition(target: LatLng(59.81, 10.44), zoom: 11.0),
            onMapLongClick: _onMapLongClick,
            onMapClick: _onMapClick,
          ),
        );
      },
    );
  }

  void _onMapLongClick(_, LatLng coordinates) {
    print('longclick');
    final mapModel = context.read<MapModel>();
    if (mapModel.clickState == ClickState.LongClick) {
      _mapController.removeSymbol(mapModel.longCLickSymbol);
    }
    SymbolOptions symbolOptions = mapModel.onMapLongClick(coordinates);
    _mapController.addSymbol(symbolOptions).then(mapModel.setLongClickSymbol);
    _showBottomSheetBuilder(coordinates.toPoint());
  }

  void _onMapClick(_, LatLng coordinates) {
    print('click');
    final mapModel = context.read<MapModel>();
    if (mapModel.clickState == ClickState.LongClick) {
      _mapController.removeSymbol(mapModel.longCLickSymbol);
    }
    mapModel.onMapClick(coordinates);
    // TODO: does not work until symbol tap is consumed before propogating here
    Navigator.popUntil(context, ModalRoute.withName('/'));
  }

  // TODO: disable propagation.
  void _onSymbolTapped(Symbol symbol) {
    print('symbol tapped');
    final mapModel = context.read<MapModel>();
    mapModel.onSymbolTapped();
    if (!symbol.data.containsKey('id')) return;
    final String campId = symbol.data['id'] as String;
    final Camp camp = mapModel.getCamp(campId);
    showBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return OpenContainerCamp(
          camp,
          closedScreen: MarkerBottomSheet(),
        );
      },
    );
  }

  void _onStyleLoaded() {
    // Subscribe to stream events
    _symbolsSubscription =
        context.read<MapModel>().campSymbolsStream.listen((element) {
          _mapController.clearSymbols();

          // TODO: batch add with addSymbols
          element.forEach((element) {
            _mapController.addSymbol(element.options, {'id': element.id});
          });
        });
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    // TODO: disable tap event propagating to mapCLick listener https://github.com/tobrun/flutter-mapbox-gl/pull/381
    _mapController.onSymbolTapped.add(_onSymbolTapped);
  }



  void _showBottomSheetBuilder(Point<double> coordinates) {
    showBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Provider<Point<double>>.value(
        value: coordinates,
        child: PointBottomSheet(),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.onSymbolTapped?.remove(_onSymbolTapped);
    _symbolsSubscription?.cancel();
    super.dispose();
  }
}
