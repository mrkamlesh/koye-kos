import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:koye_kos/popup.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

// Static fields to help set up the map
class MapInfo {
  static final mapUrl = 'https://opencache{s}.statkart.no/'
      'gatekeeper/gk/gk.open_gmaps?'
      'layers=topo4&zoom={z}&x={x}&y={y}&format=image/jpeg';
  static final mapSubdomains = ['', '2', '3'];
  static final LatLng defaultLatLng = LatLng(59.81, 10.44);
}

// pojo to camp location, future: add from.json constructor
class CampLocation {
  final String image_path;
  final LatLng point;
  final double score;
  final int ratings;
  final String description;

  CampLocation(this.image_path, this.point, this.score, this.ratings, this.description);
}

// Simulate network call to get and build map data
List<CampLocation> getCampLocations() {
  final String image_path = 'images/spot_1.jpg';
  final LatLng campPoint = LatLng(59.813833, 10.412977);
  final LatLng campPoint2 = LatLng(59.833833, 10.402977);
  final double score = 4.7;
  final int ratings = 11;
  final String description = 'This is a description of the camp, looks good!';

  return [
    CampLocation(
        image_path,
        campPoint,
        score,
        ratings,
        description
    ),
    CampLocation(
        image_path,
        campPoint2,
        score,
        ratings,
        description
    ),
  ];
}

class HammockMap extends StatefulWidget {

  @override
  _HammockMapState createState() => _HammockMapState();
}

class _HammockMapState extends State<HammockMap> {
  final PopupController _popupLayerController = PopupController();

  // simulate async call
  final List<CampMarker> _campMarkers = getCampLocations()
      .map((location) => CampMarker(location)).toList();

  @override
  Widget build(BuildContext context) {
    _popupLayerController.showPopupFor(_campMarkers.first);  // for debugging
    return FlutterMap(
      options: MapOptions(
        center: MapInfo.defaultLatLng,
        zoom: 12.0,
        plugins: [
          PopupMarkerPlugin(),
        ],
        onTap: (_) => _popupLayerController.hidePopup(), // hides popup when map is tapped
        interactive: true,
      ),
      layers: [
        TileLayerOptions(
            urlTemplate: MapInfo.mapUrl,
            subdomains: MapInfo.mapSubdomains  // loadbalancing; uses subdomains opencache[2/3].statkart.no
        ),
        MapPopupImpl.buildPopupOptions(
            campMarkers: _campMarkers,
            popupController: _popupLayerController
        ),
      ],
    );
  }
}

class CampMarker extends Marker {
  final CampLocation campLocation;

  CampMarker(this.campLocation) :
        super(
          point: campLocation.point,
          width: 40,
          height: 40,
          anchorPos: AnchorPos.align(AnchorAlign.top),
          builder: (context) => Icon(Icons.location_on, size: 40)
      );
}

class CampMarkerPopup extends StatefulWidget {
  final CampLocation _campLocation;

  CampMarkerPopup(this._campLocation, {Key key}) : super(key: key);

  @override
  _CampMarkerPopupState createState() => _CampMarkerPopupState(_campLocation);
}

class _CampMarkerPopupState extends State<CampMarkerPopup> {
  final CampLocation _campLocation;

  _CampMarkerPopupState(this._campLocation);

  @override
  Widget build(BuildContext context) =>
      MapPopupImpl.buildPopup(campLocation: _campLocation);

}