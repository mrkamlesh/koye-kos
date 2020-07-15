import 'package:flutter/foundation.dart' as Foundation;
import 'package:flutter/material.dart';
import 'models.dart';


class CampMarkerPopup extends StatelessWidget {
  final Camp _camp;

  CampMarkerPopup(this._camp);

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
              _buildImage(_camp.imageUrl),
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
    var _path = path;

    // hack to show image. TODO: firebase firestore impl for image retrieval
    if (Foundation.kDebugMode) {
      _path = 'images/spot_1_small.jpg';
    };

    return Image.asset(
      _path,
      width: 240,
      height: 160,
      fit: BoxFit.cover,
    );
  }
}

class CampDescriptionWidget extends StatelessWidget {
  final Camp _camp;
  CampDescriptionWidget({@required Camp camp,}) : _camp = camp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Location: ${_camp.location.latitude.toStringAsFixed(4)}'
            ' / ${_camp.location.longitude.toStringAsFixed(4)}'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Rating: ${_camp.score} (${_camp.ratings})'),
            Icon(Icons.star_border), // TODO: place inside image?
          ],
        ),
        Divider(),
        Text(_camp.description),
      ],
    );
  }
}
