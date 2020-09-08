import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:koye_kos/models/camp.dart';

class CampFeaturesWidget extends StatelessWidget {
  final Set<CampFeature> features;

  CampFeaturesWidget(this.features);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        ...features.map(
          (feature) => FeatureInfoChip(feature: feature),
        ),
      ],
    );
  }
}

class FeatureInfoChip extends StatelessWidget {
  final CampFeature feature;
  FeatureInfoChip({@required this.feature});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        describeEnum(feature),
      ),
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: Theme.of(context).primaryColor.withAlpha(40))),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class FeatureSelectChip extends StatelessWidget {
  final String title;
  final CampFeature feature;
  final bool isSelected;
  final Function(bool, CampFeature) onSelected;

  FeatureSelectChip({
    @required this.title,
    @required this.feature,
    @required this.isSelected,
    @required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
        onSelected: (value) => onSelected(value, feature),
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor,
        checkmarkColor: Colors.white,
        elevation: 2,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
