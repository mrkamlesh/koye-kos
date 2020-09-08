import 'package:flutter/material.dart';
import 'package:koye_kos/camp/ui/feature_chips.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:provider/provider.dart';

import 'map_model.dart';

class MapFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapModel = Provider.of<MapModel>(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 8),
          FeatureSelectChip(
            title: 'Tent',
            feature: CampFeature.Tent,
            isSelected: mapModel.tentSelected,
            onSelected: mapModel.onFeatureSelected,
          ),
          SizedBox(width: 4),
          FeatureSelectChip(
            title: 'Hammock',
            feature: CampFeature.Hammock,
            isSelected: mapModel.hammockSelected,
            onSelected: mapModel.onFeatureSelected,
          ),
          SizedBox(width: 4),
          FeatureSelectChip(
            title: 'Water nearby',
            feature: CampFeature.Water,
            isSelected: mapModel.waterSelected,
            onSelected: mapModel.onFeatureSelected,
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}
