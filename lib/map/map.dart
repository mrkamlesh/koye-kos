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

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<FirestoreService, MapModel>(
      create: (context) =>
          MapModel(firestore: context.read<FirestoreService>()),
      update: (_, firestore, mapModel) => mapModel..setFirestore(firestore),
      child: Map(),
    );
  }
}

class Map extends StatefulWidget {
  @override
  State createState() => MapState();
}

class MapState extends State<Map> {
  MapboxMapController _mapController;

  @override
  Widget build(BuildContext context) {
    print('build');
    return Consumer<MapModel>(
      builder: (context, mapModel, _) {
        return Scaffold(
          body: MapboxMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition:
                const CameraPosition(target: LatLng(59.81, 10.44), zoom: 11.0),
            onMapLongClick: (_, coordinates) {
              //mapModel.onMapLongClick(coordinates);
              print('longclick $coordinates');
              _showBottomSheetBuilder(coordinates.toPoint());
            },
            onMapClick: (_, coordinates) {
              print('click');
              //mapModel.onMapClick(coordinates);
              //Navigator.popUntil(context, ModalRoute.withName('/'));
            },
          ),
        );
      },
    );
  }

  _onMapCreated(MapboxMapController controller) {
    print('_onMapCreated');
    _mapController = controller;
    _mapController.onSymbolTapped.add(_onSymbolTapped);
    context.read<MapModel>().campSymbols.forEach((element) {
      _mapController.addSymbol(element.options, {'id': element.id});
    });
  }

  void _onSymbolTapped(Symbol symbol) {
    final String campId = symbol.data['id'] as String;
    final Camp camp = context.read<MapModel>().getCamp(campId);
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

  void _showBottomSheetBuilder(Point<double> coordinates) {
    showBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => PointBottomSheet(coordinates));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    //_mapController?.onSymbolTapped?.remove(_onSymbolTapped);
    super.dispose();
  }
}
