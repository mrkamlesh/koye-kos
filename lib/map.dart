import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:koye_kos/db.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

import 'models.dart';
import 'popup.dart';

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
  final List<CampMarker> _campMarkers = List();

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  void initAsync() {
    FirestoreService.instance
        .getCampMarkerFuture()
        .then((List<CampMarker> campMarkers) {
      setState(() {
        _campMarkers.addAll(campMarkers);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: MapInfo.defaultLatLng,
        zoom: 12.0,
        plugins: [
          PopupMarkerPlugin(),
        ],
        onTap: (_) => _popupController.hidePopup(),
        onLongPress: (point) => simulateAddCamp(point),
        // hides popup when map is tapped
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
            popupController: _popupController,
            popupBuilder: (BuildContext _, Marker marker) {
              if (marker is CampMarker) {
                return CampMarkerPopup(marker.camp);
              } else {
                return Card(child: const Text('Marker not implemented'));
              }
            }),
      ],
    );
  }

  void simulateAddCamp(LatLng point) {
    print(point);
    Camp c = Camp(
      imageUrl: 'images/spot_1_small.jpg',
      location: point,
      description: 'New added camp!'
    );
    FirestoreService.instance.addCamp(c);
    // TODO: possible to add to list locally and not need to perform another GET?
    initAsync();
  }
}

class AddCampWidget extends StatelessWidget {
  final LatLng _point;

  AddCampWidget(LatLng this._point);

  @override
  Widget build(BuildContext context) {
    print('building add camp widget');
    return Container();
  }
}


class CampMarker extends Marker {
  final Camp camp;

  CampMarker(this.camp)
      : super(
            point: camp.location,
            width: 40,
            height: 40,
            anchorPos: AnchorPos.align(AnchorAlign.top),
            builder: (context) => Icon(Icons.location_on, size: 40));
}
