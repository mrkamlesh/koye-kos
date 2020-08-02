import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:provider/provider.dart';

import 'camp_detail.dart';
import '../service/db.dart';
import '../models.dart';
import 'map_detail.dart';

// Static fields to help set up the map
class MapInfo {
  static final LatLng center = LatLng(59.81, 10.44); // default center
  static final zoom = 12.0; // default zoom level
  static final minZoom = 4.0; // map zoom limits
  static final maxZoom = 18.0;
  static final swPanBoundary = LatLng(58, 4.0); // map pan boundaries
  static final nePanBoundary = LatLng(71.0, 31.0);
}

enum MapType { topo, grunn }

class MapProvider {
  MapKartverket mapKartverket = MapKartverket();

  Widget getMap({MapType type}) {
    if (type == MapType.topo) return mapKartverket.layerKartverketTopo;
    if (type == MapType.grunn) return mapKartverket.layerKartverketGrunn;
  }
}

class MapKartverket {
  static final mapTopo = 'https://opencache{s}.statkart.no/'
      'gatekeeper/gk/gk.open_gmaps?'
      'layers=topo4&zoom={z}&x={x}&y={y}&format=image/jpeg';

  static final mapGrunn = 'https://opencache{s}.statkart.no/'
      'gatekeeper/gk/gk.open_gmaps?'
      'layers=norges_grunnkart&zoom={z}&x={x}&y={y}&format=image/jpeg';

  static final mapSubdomains = ['', '2', '3'];

  final Widget layerKartverketTopo = TileLayerWidget(
    options: TileLayerOptions(
      urlTemplate: mapTopo,
      subdomains:
          mapSubdomains, // loadbalancing; uses subdomains opencache[2/3].statkart.no
    ),
  );

  final Widget layerKartverketGrunn = TileLayerWidget(
    options: TileLayerOptions(
      urlTemplate: mapGrunn,
      subdomains: mapSubdomains,
    ),
  );
}

class HammockMap extends StatefulWidget {
  @override
  _HammockMapState createState() => _HammockMapState();
}

class _HammockMapState extends State<HammockMap> {
  LatLng _longpressPoint;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final MapProvider _mapProvider = MapProvider();

  Widget _tileLayerWidget;

  @override
  void initState() {
    _tileLayerWidget = _mapProvider.mapKartverket.layerKartverketTopo;
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            center: MapInfo.center,
            zoom: MapInfo.zoom,
            minZoom: MapInfo.minZoom,
            maxZoom: MapInfo.maxZoom,
            swPanBoundary: MapInfo.swPanBoundary,
            nePanBoundary: MapInfo.nePanBoundary,
            interactive: true,
            onTap: (_) {
              // Tapping the map should remove all other widgets
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
            onLongPress: (point) {
              setState(() {
                _longpressPoint = point;
              });
              showBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return PointBottomSheet(point);
                  }).closed.then((_) {
                setState(() {
                  // removed point marker when closing pointDetail
                  _longpressPoint = null;
                });
              });
            },
          ),
          children: [
            // Map provider
            _tileLayerWidget,
            // Longpress marker
            MarkerLayerWidget(
              options: MarkerLayerOptions(markers: <Marker>[
                if (_longpressPoint != null)
                  createLongpressMarker(_longpressPoint),
              ]),
            ),
            CampMarkerLayer(tapCallback: () {
              setState(() {
                _longpressPoint = null;
              });
            }),
          ],
        ),
        MapLayerPopup(
          selectionCallback: ((MapType selection) {
            setState(() {
              _tileLayerWidget = _mapProvider.getMap(type: selection);
            });
          }),
        ),
      ],
    );
  }
}

class MapLayerPopup extends StatelessWidget {
  final Function(MapType) selectionCallback;
  MapLayerPopup({this.selectionCallback});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      top: 12,
      child: PopupMenuButton<MapType>(
        child: Material(
          type: MaterialType.circle,
          elevation: 1,
          color: Colors.grey.shade50,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              Icons.layers,
              size: 20,
              color: Colors.black87,
            ),
          ),
        ),
        onSelected: (MapType result) {
          selectionCallback(result);
        },
        itemBuilder: (context) => <PopupMenuEntry<MapType>>[
          PopupMenuItem<MapType>(
            value: MapType.topo,
            child: Text('Topografisk'),
          ),
          PopupMenuItem<MapType>(
            value: MapType.grunn,
            child: Text('Grunnkart'),
          ),
        ],
      ),
    );
  }
}

class CampMarkerLayer extends StatelessWidget {
  final Function tapCallback;
  CampMarkerLayer({this.tapCallback});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.watch<FirestoreService>().getCampListStream(),
      builder: (BuildContext context, AsyncSnapshot<List<Camp>> snapshot) {
        return MarkerLayerWidget(
          options: MarkerLayerOptions(
            markers: [
              if (snapshot.hasData)
                ...snapshot.data.map((Camp camp) {
                  return CampMarker(camp, tapCallback: () {
                    tapCallback();
                    // TODO: change marker icon to red when tapped
                    showBottomSheet<void>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _OpenContainerCamp(camp: camp));
                  });
                })
            ],
          ),
        );
      },
    );
  }
}

class _OpenContainerCamp extends StatelessWidget {
  final Camp camp;
  _OpenContainerCamp({this.camp});
  // TODO: fix widgets rebuilding during animation, likely cause for poor performance

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final String userId = context.select((FirebaseUser user) => user.uid);

    return OpenContainer(
      closedColor: Colors.transparent,
      closedShape: const RoundedRectangleBorder(),
      closedElevation: 0,
      openElevation: 0,
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return MultiProvider(
          providers: [
            StreamProvider<Camp>(
              create: (_) => firestoreService.getCampStream(camp.id),
              initialData: camp,
            ),
            StreamProvider<bool>(
              create: (_) =>
                  firestoreService.campFavoritedStream(userId, camp.id),
              initialData: false,
            ),
          ],
          child: MarkerBottomSheet(),
        );
      },
      openBuilder: (BuildContext context, VoidCallback _) {
        return MultiProvider(
          providers: [
            StreamProvider<Camp>(
              create: (_) => firestoreService.getCampStream(camp.id),
              initialData: camp,
            ),
            StreamProvider<bool>(
              create: (_) =>
                  firestoreService.campFavoritedStream(userId, camp.id),
              initialData: false,
            ),
          ],
          child: CampDetailScreen(),
        );
      },
    );
  }
}

class CampMarker extends Marker {
  final Camp camp;
  final Function tapCallback;

  CampMarker(this.camp, {this.tapCallback})
      : super(
          point: camp.location,
          width: 40,
          height: 40,
          anchorPos: AnchorPos.align(AnchorAlign.top),
          builder: (context) => Container(
            child: GestureDetector(
              onTap: () {
                tapCallback();
              },
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
    ),
  );
}
