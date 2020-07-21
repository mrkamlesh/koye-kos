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
  static final LatLng center = LatLng(59.81, 10.44); // default center
  static final zoom = 12.0; // default zoom level
  static final minZoom = 4.0; // map zoom limits
  static final maxZoom = 18.0;
  static final swPanBoundary = LatLng(58, 4.0); // map pan boundaries
  static final nePanBoundary = LatLng(71.0, 31.0);
}

class HammockMap extends StatefulWidget {
  @override
  _HammockMapState createState() => _HammockMapState();
}

class _HammockMapState extends State<HammockMap> {
  LatLng _longpressPoint;
  PersistentBottomSheetController _markerDetailController;
  PersistentBottomSheetController _pointDetailController;
  // used to control sheetController states (since only one can be shown/closed at a time)
  bool isShowingPointDetail = false;
  bool isShowingMarkerDetail = false;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder(
      stream: firestoreService.getCampStream(),
      builder: (BuildContext context, AsyncSnapshot<List<Camp>> snapshot) {
        return FlutterMap(
          options: MapOptions(
            center: MapInfo.center,
            zoom: MapInfo.zoom,
            minZoom: MapInfo.minZoom,
            maxZoom: MapInfo.maxZoom,
            swPanBoundary: MapInfo.swPanBoundary,
            nePanBoundary: MapInfo.nePanBoundary,
            interactive: true,
            onTap: (_) {
              // If bottomSheet is not showing, the controller would throw exception if trying to close it
              print(isShowingPointDetail);
              print(isShowingMarkerDetail);

              if (isShowingPointDetail | isShowingMarkerDetail)
                Navigator.pop(context);
            },
            onLongPress: (point) {
              setState(() {
                _longpressPoint = point;
                isShowingPointDetail = true;
                isShowingMarkerDetail = false;
              });
              _pointDetailController = showBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return PointBottomSheet(point);
                  });
              _pointDetailController.closed.then((_) {
                setState(() {
                  _longpressPoint =
                      null; // removed point marker when closing pointDetail
                });
              });
            },
          ),
          children: [
            TileLayerWidget(
                options: TileLayerOptions(
                    urlTemplate: MapInfo.mapUrl,
                    subdomains: MapInfo
                        .mapSubdomains // loadbalancing; uses subdomains opencache[2/3].statkart.no
                    )),
            MarkerLayerWidget(
              options: MarkerLayerOptions(
                markers: [
                  if (_longpressPoint != null)
                    createLongpressMarker(_longpressPoint),
                  if (snapshot.hasData)
                    ...snapshot.data.map((Camp camp) {
                      return CampMarker(camp, () {
                        if (isShowingPointDetail) Navigator.pop(context);

                        setState(() {
                          _longpressPoint = null;
                          isShowingPointDetail = false;
                          isShowingMarkerDetail = true;
                        });
                        _markerDetailController = showBottomSheet<void>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) {
                              return MarkerBottomSheet(camp);
                            });
                        _markerDetailController.closed.then((value) {
                          setState(() {
                            isShowingMarkerDetail = false;
                          });
                        });
                      });
                    }),
                ],
              ),
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
