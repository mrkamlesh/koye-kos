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
  final PopupController _popupController = PopupController();
  LatLng _longpressPoint;
  PersistentBottomSheetController _bottomSheetController;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return StreamBuilder(
      stream: firestoreService.getCampMarkerStream(),
      builder: (context, snapshot) {
        return FlutterMap(
          options: MapOptions(
            center: MapInfo.defaultLatLng,
            zoom: 4.0,
            minZoom: 4.0,
            maxZoom: 18.0,
            swPanBoundary: LatLng(58, 4.0),
            nePanBoundary: LatLng(71.0, 31.0),
            interactive: true,
            plugins: [
              PopupMarkerPlugin(),
            ],
            onTap: (_) {
              _popupController.hidePopup();
              _bottomSheetController?.close();
            },
            onLongPress: (point) {
              setState(() {
                _longpressPoint = point;
              });
              _bottomSheetController = showBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (BuildContext sheetContext) {
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
                            title: Text(point.toReadableString(
                                precision: 4, separator: ', ')),
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
                                          sheetContext,
                                          MaterialPageRoute<bool>(
                                              builder: (context) =>
                                                  AddCampScreen(point)))
                                      .then((bool campAdded) {
                                    if (campAdded) {
                                      Navigator.pop(context);
                                      Scaffold.of(context)
                                        ..removeCurrentSnackBar()
                                        ..showSnackBar(SnackBar(
                                            content: Text('Camp added!')));
                                    }
                                  });
                                })),
                      ),
                    ),
                  );
                },
              );
              _bottomSheetController.closed.then((_) {
                setState(() {
                  _longpressPoint = null;
                });
              });
            },
            // hides popup when map is tapped
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
            MarkerLayerOptions(
              markers: [
                if (_longpressPoint != null) createMarker(_longpressPoint),
              ],
            ),
          ],
          // PopupMarkerLayerOptions does not support new Widget layer pattern
          // MarkerLayerOptions should be like below, but this does not work with popuplayeroptions;
          /*children: [
            MarkerLayerWidget(
              options:  MarkerLayerOptions(
                markers: [
                  if (_longpressPoint != null) createMarker(_longpressPoint),
                ],
              ),)
          ],*/
        );
      },
    );
  }
}

class AddCampScreen extends StatelessWidget {
  final LatLng location;

  AddCampScreen(this.location);

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
                  if (value.length < 0) {
                    // PROD: change to meaningful value
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
                      imageUrl: 'spot_1_small.jpg',
                      description: descriptionController.text,
                      location: widget._location,
                      creatorName: user.displayName,
                      creatorId: user.uid,
                    );
                    //firestoreService.addCamp(newCamp);
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

Marker createMarker(LatLng point) {
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
