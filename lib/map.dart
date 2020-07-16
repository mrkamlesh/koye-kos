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
            onLongPress: (point) {
              Navigator.push(
                  context,
                  MaterialPageRoute<bool>(
                      builder: (context) => AddCampScreen(point)))
                  .then((bool campAdded) {
                if (campAdded) {
                  Scaffold.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text('Camp added!')));
                }
              });
            },
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
}

class AddCampScreen extends StatelessWidget {
  final LatLng location;

  AddCampScreen(LatLng this.location);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add camp'),
      ),
      body: CampForm(location),
    );
  }
}

class CampForm extends StatefulWidget {
  final LatLng _location;
  CampForm(this._location);

  @override
  _CampFormState createState() => _CampFormState();
}

class _CampFormState extends State<CampForm> {
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Location: ${widget._location.latitude.toStringAsFixed(4)}, ${widget._location.longitude.toStringAsFixed(4)}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextFormField(
                controller: descriptionController,
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
                  if (value.length < 0) {  // PROD: change to meaningful value
                    return 'Please enter short a description!';
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
                    print('camp added');
                    Camp newCamp = Camp(
                      imageUrl: 'nan',
                      description: descriptionController.text,
                      location: widget._location,
                      creatorName: user.displayName,
                      creatorId: user.uid,
                    );
                    firestoreService.addCamp(newCamp);
                    Navigator.pop(context, true);
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

  @override
  void dispose() {
    super.dispose();
    descriptionController.dispose();
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
