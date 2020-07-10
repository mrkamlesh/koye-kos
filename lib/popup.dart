import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'data.dart';
import 'map.dart';


class CardPopupImpl extends StatelessWidget {
  final Camp _camp;
  CardPopupImpl(this._camp);

  @override
  Widget build(BuildContext context) {
    print('build card');
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
              _buildImage(_camp.image_path),
              Container(
                padding: EdgeInsets.all(8),
                child: CampDescriptionWidget(camp: _camp),
              ),
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
}

class CampDescriptionWidget extends StatelessWidget {
  const CampDescriptionWidget({
    Key key,
    @required Camp camp,
  }) : _camp = camp, super(key: key);

  final Camp _camp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Location: ${_camp.point.latitude.toStringAsFixed(4)}'
            ' / ${_camp.point.longitude.toStringAsFixed(4)}'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Rating: 4.8 (22)'),
            Icon(Icons.star_border), // TODO: place inside image?
          ],
        ),
        Divider(),
        Text(
            "This is a short description of the camping spot; it's amazing"),
      ],
    );
  }
}
