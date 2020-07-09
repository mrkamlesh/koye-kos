import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class MapInfo {
  static final mapUrl = 'https://opencache{s}.statkart.no/'
      'gatekeeper/gk/gk.open_gmaps?'
      'layers=topo4&zoom={z}&x={x}&y={y}&format=image/jpeg';
  static final mapSubdomains = ['', '2', '3'];
  static final LatLng defaultLatLng = LatLng(59.81, 10.44);
}


class HammockMap extends StatelessWidget {

  Image image = Image.asset(
    'spot_1.jpg',
    width: 20,
    height: 20,
    fit: BoxFit.cover,
  );
  static final LatLng campPoint = LatLng(59.813833, 10.412977);

  List<Marker> markers = <Marker> [
    Marker(
      point: campPoint,
      width: 40,
      height: 40,
      anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (context) => Icon(Icons.location_on, size: 40),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: MapInfo.defaultLatLng,
        zoom: 12.0,
      ),
      layers: [
        TileLayerOptions(
            urlTemplate: MapInfo.mapUrl,
            subdomains: MapInfo.mapSubdomains),  // loadbalancing; uses subdomains opencache[2/3].statkart.no
        MarkerLayerOptions(
          markers: markers,
        ),
      ],
    );
  }
}

