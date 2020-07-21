import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'models.dart';
import 'map_detail.dart';

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
  LatLng _longpressPoint;
  PersistentBottomSheetController _markerDetailController;
  PersistentBottomSheetController _pointDetailController;
  bool isShowingPointDetail = false;  // used to control sheetController states (since only one can be shown/closed at a time)

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder(
      stream: firestoreService.getCampStream(),
      builder: (BuildContext context, AsyncSnapshot<List<Camp>> snapshot) {
        return FlutterMap(
          options: MapOptions(
            center: MapInfo.defaultLatLng,
            zoom: 12.0,
            minZoom: 4.0,
            maxZoom: 18.0,
            swPanBoundary: LatLng(58, 4.0),
            nePanBoundary: LatLng(71.0, 31.0),
            interactive: true,
            onTap: (_) {
              // If bottomSheet is not showing, the controller would throw exception if trying to close it
              if (isShowingPointDetail) _pointDetailController?.close();
              else _markerDetailController?.close();
            },
            onLongPress: (point) {
              setState(() {
                _longpressPoint = point;
                isShowingPointDetail = true;
              });
              _pointDetailController = showBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext sheetContext) {
                    return PointBottomSheet(point);
                  });
              _pointDetailController.closed.then((_) {
                setState(() {
                  _longpressPoint = null;  // removed point marker when closing pointDetail
                });
              });
            },
          ),
          layers: [
            TileLayerOptions(
                urlTemplate: MapInfo.mapUrl,
                subdomains: MapInfo
                    .mapSubdomains // loadbalancing; uses subdomains opencache[2/3].statkart.no
                ),
            MarkerLayerOptions(
              markers: [
                if (_longpressPoint != null)
                  createLongpressMarker(_longpressPoint),
                if (snapshot.hasData)
                  ...snapshot.data.map((Camp camp) {
                    return CampMarker(camp, () {
                      setState(() {
                        _longpressPoint = null;
                        isShowingPointDetail = false;
                      });
                      _markerDetailController = showBottomSheet<void>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext sheetContext) {
                            return MarkerBottomSheet(camp);
                          });
                    });
                  }),
              ],
            ),
          ],
        );
      },
    );
  }
}

class CampMarker extends Marker {
  final Camp camp;
  final Function _callback;

  CampMarker(this.camp, this._callback)
      : super(
          point: camp.location,
          width: 40,
          height: 40,
          anchorPos: AnchorPos.align(AnchorAlign.top),
          builder: (context) => Container(
            child: GestureDetector(
              onTap: () => _callback(),
              child: Icon(Icons.location_on, size: 40),
            ),
          ),
        );
}

Marker createLongpressMarker(LatLng point) {
  return Marker(
      point: point,
      width: 45,
      height: 45,
      anchorPos: AnchorPos.align(AnchorAlign.top),
      builder: (context) => Icon(
            Icons.location_on,
            size: 45,
            color: Colors.red,
          ));
}
