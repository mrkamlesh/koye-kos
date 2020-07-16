import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:koye_kos/db.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<FirebaseUser>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder(
      stream: firestoreService.getCampMarkerStream(),
      builder: (context, snapshot) {
        return FlutterMap(
          options: MapOptions(
            center: MapInfo.defaultLatLng,
            zoom: 12.0,
            plugins: [
              PopupMarkerPlugin(),
            ],
            onTap: (_) => _popupController.hidePopup(),
            onLongPress: (point) => Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddCampWidget(point))),
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
                markers: snapshot.data ?? List(),
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
      },
    );
  }

  void simulateAddCamp(LatLng point, FirebaseUser user) {
    print('simulateAddCamp: $point');
    Camp c = Camp(
        imageUrl: 'images/spot_1_small.jpg',
        location: point,
        description: 'New added camp!',
        creatorId: user.uid,
        creatorName: user.displayName);
    FirestoreService.instance.addCamp(c);
    // TODO: possible to add to list locally and not need to perform another GET?
    // or switch to stream but this will use more data.. would also handle when user deletes post
  }
}

class AddCampWidget extends StatelessWidget {
  final LatLng _point;

  AddCampWidget(LatLng this._point);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add camp'),
      ),
      body: CampForm(_point),
    );
  }
}

class CampForm extends StatefulWidget {
  final LatLng _point;
  CampForm(this._point);

  @override
  _CampFormState createState() => _CampFormState();
}

class _CampFormState extends State<CampForm> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Location: ${widget._point.latitude.toStringAsFixed(4)}, ${widget._point.longitude.toStringAsFixed(4)}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextFormField(
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                    hintText: 'Enter a short camp description',
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(),
                    )),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a description!';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: RaisedButton(
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    Scaffold.of(context)
                        .showSnackBar(SnackBar(content: Text('Camp added!')));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add camp'),
              ),
            )
          ],
        ),
      ),
    );
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
