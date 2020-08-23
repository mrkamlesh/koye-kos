import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:koye_kos/map/map_detail.dart';
import 'package:koye_kos/services/db.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

import 'map_model.dart';
import '../utils.dart';

class MapScreen extends StatefulWidget {
  @override
  State createState() => FullMapState();
}

class FullMapState extends State<MapScreen> {
  MapboxMapController _mapController;

  _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return ChangeNotifierProxyProvider<FirestoreService, MapModel>(
      create: (context) => MapModel(firestore: context.read<FirestoreService>()),
      update: (_, firestore, mapModel) => mapModel..setFirestore(firestore),
      child: Consumer<MapModel>(
        builder: (context, mapModel, child) {

          void _showBottomSheetBuilder(Point<double> coordinates) {
            showBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => PointBottomSheet(coordinates)
            );
          }
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
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
            ),
          );
        },
      ),
    );
  }
}

