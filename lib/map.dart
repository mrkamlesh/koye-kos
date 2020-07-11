import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:koye_kos/popup.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

import 'data.dart';

// Static fields to help set up the map
class MapInfo {
  static final mapUrl = 'https://opencache{s}.statkart.no/'
      'gatekeeper/gk/gk.open_gmaps?'
      'layers=topo4&zoom={z}&x={x}&y={y}&format=image/jpeg';
  static final mapSubdomains = ['', '2', '3'];
  static final LatLng defaultLatLng = LatLng(59.81, 10.44);
}

class HammockMap extends StatefulWidget {
  @override
  _HammockMapState createState() => _HammockMapState();
}

class _HammockMapState extends State<HammockMap> {
  final PopupController _popupController = PopupController();
  List<Camp> _camps = List();

  @override
  void initState() {
    super.initState();
    asyncInit();
  }

  // FIXME: widgets are not rebuilt!!!
  void asyncInit() async {
    Firestore.instance
        .collection('camps')
        .getDocuments()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        print('setstate');
        _camps.addAll(querySnapshot.documents
            .map((document) => Camp.fromJson(document.data))
            .toList());
      });
    }
    )
        .catchError((e) => print('error'));
  }

  @override
  Widget build(BuildContext context) {
    print('building map ${_camps.isNotEmpty ? _camps.first : 'empty list'}');

    var campMarkers = _camps.map((camp) => CampMarker(camp)).toList();
    if (campMarkers.isNotEmpty) {
      _popupController.showPopupFor(campMarkers.first); // for debugging
    }


    return FlutterMap(
      options: MapOptions(
        center: MapInfo.defaultLatLng,
        zoom: 12.0,
        plugins: [
          PopupMarkerPlugin(),
        ],
        onTap: (_) =>
            _popupController.hidePopup(), // hides popup when map is tapped
        interactive: true,
      ),
      layers: [
        TileLayerOptions(
            urlTemplate: MapInfo.mapUrl,
            subdomains: MapInfo
                .mapSubdomains // loadbalancing; uses subdomains opencache[2/3].statkart.no
        ),
        PopupMarkerLayerOptions(
            markers: campMarkers,
            popupSnap: PopupSnap.top,
            popupController: _popupController,
            popupBuilder: (BuildContext _, Marker marker) {
              print('popupbuilder');
              if (marker is CampMarker) {
                return CampMarkerPopup(marker.camp);
              } else {
                return Card(child: const Text('Not a monument'));
              }
            }
        ),
      ],
    );
  }
}

class CampMarker extends Marker {
  final Camp camp;

  CampMarker(this.camp)
      : super(
      point: camp.point,
      width: 40,
      height: 40,
      anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (context) => Icon(Icons.location_on, size: 40));
}


