import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'map_model.dart';
import 'map_utils.dart';

class GpsButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapModel = Provider.of<MapModel>(context);
    return SizedBox(
      width: 40,
      height: 40,
      child: FloatingActionButton(
        elevation: 2,
        onPressed: mapModel.onGpsClick,
        backgroundColor: Colors.grey.shade50,
        child: Icon(
          Icons.gps_fixed,
          size: 20,
          color: mapModel.locationTracking ? Colors.blue : Colors.black87,
        ),
      ),
    );
  }
}

class MapStyleButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapModel = Provider.of<MapModel>(context);
    return Material(
      type: MaterialType.circle,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      color: Colors.grey.shade50,
      child: SizedBox(
        width: 40,
        height: 40,
        child: PopupMenuButton<MapStyle>(
          child: Icon(
            Icons.layers,
            size: 20,
            color: Colors.black87,
          ),
          onSelected: mapModel.onStyleSelected,
          itemBuilder: (context) => <PopupMenuEntry<MapStyle>>[
            PopupMenuItem<MapStyle>(
              value: MapStyle.Outdoors,
              child: Text('Outdoor'),
            ),
            PopupMenuItem<MapStyle>(
              value: MapStyle.Satellite,
              child: Text('Satellite'),
            ),
          ],
        ),
      ),
    );
  }
}
