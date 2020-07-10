import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'data.dart';
import 'map.dart';

// The logic of building the popup card, extract so it can easily be changed to another impl
//
class MapPopupImpl {

  static PopupMarkerLayerOptions buildPopupOptions({
    @required  List<Marker> campMarkers,
    @required PopupController popupController}) {

    return PopupMarkerLayerOptions(
        markers: campMarkers,
        popupSnap: PopupSnap.top,
        popupController: popupController,
        popupBuilder: (BuildContext _, Marker marker) {
          if (marker is CampMarker) {
            return CampMarkerPopup(marker.campLocation);
          } else {
            return Card(child: const Text('Not a monument'));
          }
        }
    );
  }
  // NOTE: anti-pattern to have functions build widgets
  static Widget buildPopup({@required Camp campLocation}) {
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
              _buildImage(campLocation.image_path),
              _buildDescription(campLocation),
            ],
          ),
        ),
        onTap: () => print('clicked'),
      ),
    );
  }

  static Widget _buildImage(String path) {
    return Image.asset(
      path,
      width: 240,
      height: 160,
      fit: BoxFit.cover,
    );
  }

  static Widget _buildDescription(Camp campLocation) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Text('Location: ${campLocation.point.latitude.toStringAsFixed(4)}'
              ' / ${campLocation.point.longitude.toStringAsFixed(4)}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Rating: 4.8 (22)'),
              Icon(Icons.star_border),  // TODO: place inside image?
            ],
          ),
          Divider(),
          Text("This is a short description of the camping spot; it's amazing"),
        ],
      ),
    );
  }
}