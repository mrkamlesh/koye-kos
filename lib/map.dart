import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';


class MapInfo {
  static final mapUrl = 'https://opencache{s}.statkart.no/'
      'gatekeeper/gk/gk.open_gmaps?'
      'layers=topo4&zoom={z}&x={x}&y={y}&format=image/jpeg';
  static final mapSubdomains = ['', '2', '3'];
  static final LatLng defaultLatLng = LatLng(59.81, 10.44);
}


class HammockMap extends StatefulWidget {
  static final LatLng campPoint = LatLng(59.813833, 10.412977);

  @override
  _HammockMapState createState() => _HammockMapState();
}

class _HammockMapState extends State<HammockMap> {
  final PopupController _popupLayerController = PopupController();

  List<Marker> _markers = <Marker> [
    Marker(
      point: HammockMap.campPoint,
      width: 40,
      height: 40,
      anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (context) => Icon(Icons.location_on, size: 40),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    _popupLayerController.showPopupFor(_markers.first);  // for debugging
    return FlutterMap(
      options: MapOptions(
        center: MapInfo.defaultLatLng,
        zoom: 12.0,
        plugins: [
          PopupMarkerPlugin()
        ],
        onTap: (_) => _popupLayerController.hidePopup(), // hides popup when map is tapped
        interactive: true,
      ),
      layers: [
        TileLayerOptions(
            urlTemplate: MapInfo.mapUrl,
            subdomains: MapInfo.mapSubdomains),  // loadbalancing; uses subdomains opencache[2/3].statkart.no
        PopupMarkerLayerOptions(
            markers: _markers,
            popupSnap: PopupSnap.top,
            popupController: _popupLayerController,
            popupBuilder: (BuildContext _, Marker marker) => CampPopup(marker)
        ),
      ],
    );
  }
}

class CampPopup extends StatefulWidget {
  final Marker marker;

  CampPopup(this.marker, {Key key}) : super(key: key);

  @override
  _CampPopupState createState() => _CampPopupState(marker);
}

class _CampPopupState extends State<CampPopup> {
  final Marker _marker;

  // this should be supplied
  final Image image = Image.asset(
    'images/spot_1.jpg',
    width: 240,
    height: 160,
    fit: BoxFit.cover,
  );

  _CampPopupState(this._marker);

  @override
  Widget build(BuildContext context) {
    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      elevation: 24,
      child: InkWell(
        child: Container(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              image,
              _buildDescription(),
            ],
          ),
        ),
        onTap: () => print('clicked'),
      ),
    );
  }

  Container _buildDescription() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Text('Location: ${_marker.point.latitude.toStringAsFixed(4)}'
              ' / ${_marker.point.longitude.toStringAsFixed(4)}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Rating: 4.8 (22)'),
              Icon(Icons.star_border),  // TODO: place inside image?
            ],
          ),
          Divider(),
          Text("This is a sort description of the camping spot; it's amazing"),
        ],
      ),
    );
  }
}

