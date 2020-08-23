import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:koye_kos/map/map_detail.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

import 'map_model.dart';
import '../utils.dart';

class MapScreen extends StatefulWidget {
  @override
  State createState() => FullMapState();
}

class FullMapState extends State<MapScreen> {
  MapboxMapController mapController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MapModel(),
      child: Consumer<MapModel>(
        builder: (context, mapModel, child) {

          void _showBottomSheetBuilder(Point<double> coordinates) {
            showBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) {
                return PointBottomSheet(coordinates);
              },
            );
          }
          return Scaffold(
            body: MapboxMap(
              initialCameraPosition:
              const CameraPosition(target: LatLng(59.81, 10.44), zoom: 11.0),
              onMapLongClick: (_, coordinates) {
                mapModel.onMapLongClick(coordinates);
                if (mapModel.clickState == ClickState.LongClick) {
                  _showBottomSheetBuilder(mapModel.longClickCoordinates);
                }
              },
              onMapClick: (_, coordinates) {
                mapModel.onMapClick(coordinates);
                if (mapModel.clickState == ClickState.Click) {
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

