import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:koye_kos/db.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:provider/provider.dart';

import 'add_camp.dart';
import 'models.dart';
import 'popup.dart';
import 'utils.dart';

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

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);

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
              // FIXME: use stateful widget eg to control visibility.
              // This crashes when detailController is open.
              _pointDetailController?.close();
              _markerDetailController?.close();
            },
            onLongPress: (point) {
              setState(() {
                _longpressPoint = point;
              });
              _pointDetailController = showBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext sheetContext) {
                    return PointBottomSheet(point);
                  });
              _pointDetailController.closed.then((_) {
                setState(() {
                  _longpressPoint = null;
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
                if (_longpressPoint != null) createLongpressMarker(_longpressPoint),
                if (snapshot.hasData)
                  ...snapshot.data.map((Camp camp) {
                    return CampMarker(camp, () {
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

class MarkerBottomSheet extends StatelessWidget {
  final Camp _camp;
  MarkerBottomSheet(this._camp);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);

    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 24,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CampDetailScreen(
                    _camp), // Probably should use some provider approach here?
              ));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildImage(_camp.imageUrl),
                  SizedBox(width: 4),
                  _buildImage(_camp.imageUrl), // Fake some more images
                  SizedBox(width: 4),
                  _buildImage(_camp.imageUrl),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                  'Location: ${_camp.location.toReadableString(precision: 4, separator: ', ')}'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Rating: ${_camp.score} (${_camp.ratings})'),
                StreamBuilder<bool>(
                    stream: firestoreService.campFavoritedStream(
                        user.uid, _camp.id),
                    builder: (context, snapshot) {
                      bool isFavorited = snapshot.data ?? false;
                      return IconButton(
                        icon: isFavorited
                            ? Icon(Icons.star)
                            : Icon(Icons.star_border),
                        onPressed: () {
                          firestoreService.setFavorited(user.uid, _camp.id,
                              favorited: !isFavorited);
                        },
                      );
                    }),
              ],
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_camp.description),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('By: ${_camp.creatorName}'),
            )
          ],
        ),
      ),
    );
    ;
  }
  
  static Widget _buildImage(String path) {
    return FutureBuilder(
        future: FirebaseStorage.instance.ref().child(path).getData(1000000),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data,
              fit: BoxFit.cover,
            );
          } else if (snapshot.hasError) {
            return Text('Error loading image: ${snapshot.error}');
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Loading image...'),
                  ),
                ],
              ),
            );
          }
        });
  }
}

class PointBottomSheet extends StatelessWidget {
  final LatLng _point;
  PointBottomSheet(this._point);

  @override
  Widget build(BuildContext context) {
    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 24,
      child: InkWell(
        child: Container(
          child: ListTile(
              leading: Icon(Icons.location_on, color: Colors.red),
              title:
                  Text(_point.toReadableString(precision: 4, separator: ', ')),
              trailing: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  color: Colors.blue,
                  textColor: Colors.white,
                  child: Text('Add camp'),
                  onPressed: () {
                    //Navigator.pop(context);  // removes bottomsheet
                    Navigator.push(
                            context,
                            MaterialPageRoute<bool>(
                                builder: (context) => AddCampScreen(_point)))
                        .then((bool campAdded) {
                      if (campAdded ?? false) {
                        Navigator.pop(context);
                        Scaffold.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(
                              SnackBar(content: Text('Camp added!')));
                      }
                    });
                  })),
        ),
      ),
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
