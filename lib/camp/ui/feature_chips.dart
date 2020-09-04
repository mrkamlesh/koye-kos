import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/camp/providers/camp_model.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:provider/provider.dart';

class CampFeaturesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final campModel = Provider.of<CampModel>(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        ...campModel.camp.features.map((feature) => FeatureChip(feature: feature), // FIXME: hey look a hack
        ),
      ],
    );
  }
}

class FeatureChip extends StatelessWidget {
  final CampFeature feature;
  FeatureChip({@required this.feature});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        describeEnum(feature),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
