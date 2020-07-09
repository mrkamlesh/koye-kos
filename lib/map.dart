import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class MapInfo {
  static final mapUrl = 'https://opencache{s}.statkart.no/'
      'gatekeeper/gk/gk.open_gmaps?'
      'layers=topo4&zoom={z}&x={x}&y={y}&format=image/jpeg';
  static final mapSubdomains = ['', '2', '3'];
}


class HammockMap extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(59.81, 10.44),
        zoom: 12.0,
      ),
      layers: [
        TileLayerOptions(
            urlTemplate: MapInfo.mapUrl,
            subdomains: MapInfo.mapSubdomains),  // loadbalancing; uses subdomains opencache[2/3].statkart.no
        MarkerLayerOptions(
          markers: [
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(59.81, 10.44),
              builder: (ctx) =>
                  Container(
                      child: FlutterLogo(),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}