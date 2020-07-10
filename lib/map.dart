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
  final PopupController _popupLayerController = PopupController();
  final List<CampMarker> _campMarkers = List();

  @override
  void initState() {
    super.initState();
    asyncInit();
  }

  void asyncInit() async {
    Firestore.instance
        .collection('camps')
        .getDocuments()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        print('setstate');
        _campMarkers.addAll(querySnapshot.documents
            .map((document) => Camp.fromJson(document.data))
            .map((camp) => CampMarker(camp))
            .toList());
      });
    }
    )
        .catchError((e) => print('error'));
  }

  @override
  Widget build(BuildContext context) {
    //_popupLayerController.showPopupFor(_campMarkers.first);  // for debugging
    print('building map $_campMarkers');

    return FlutterMap(
      options: MapOptions(
        center: MapInfo.defaultLatLng,
        zoom: 12.0,
        plugins: [
          PopupMarkerPlugin(),
        ],
        onTap: (_) =>
            _popupLayerController.hidePopup(), // hides popup when map is tapped
        interactive: true,
      ),
      layers: [
        TileLayerOptions(
            urlTemplate: MapInfo.mapUrl,
            subdomains: MapInfo
                .mapSubdomains // loadbalancing; uses subdomains opencache[2/3].statkart.no
        ),
        PopupMarkerLayerOptions(
            markers: _campMarkers,
            popupSnap: PopupSnap.top,
            popupController: _popupLayerController,
            popupBuilder: (BuildContext _, Marker marker) {
              if (marker is CampMarker) {
                print('is campmarker');
                return CampMarkerPopup(marker.camp);
              } else {
                return Card(child: const Text('Not a monument'));
              }
            }),
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

class CampMarkerPopup extends StatefulWidget {
  final Camp _camp;

  CampMarkerPopup(this._camp, {Key key}) : super(key: key);

  @override
  _CampMarkerPopupState createState() => _CampMarkerPopupState(_camp);
}

class _CampMarkerPopupState extends State<CampMarkerPopup> {
  final Camp _camp;

  _CampMarkerPopupState(this._camp);

  @override
  Widget build(BuildContext context) => CardPopupImpl(_camp);
}
