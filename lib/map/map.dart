import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class MapScreen extends StatefulWidget {

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<MapScreen> {
  MapboxMapController mapController;

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: MapboxMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition:
          const CameraPosition(target: LatLng(59.81, 10.44), zoom: 11.0,
          ),
        )
    );
  }
}