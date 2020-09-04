import 'package:flutter/material.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:provider/provider.dart';

import 'map_model.dart';

class MapFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapModel = Provider.of<MapModel>(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterChip(
            selected: mapModel.tentSelected,
            label: Text('Tent', style: TextStyle(color: mapModel.tentSelected ? Colors.white : Colors.black),),
            onSelected: (value) => mapModel.onFilterChipSelected(value, CampFeature.Tent),
            backgroundColor: Colors.white,
            selectedColor: Theme.of(context).primaryColor,
            checkmarkColor: Colors.white,
            elevation: 1,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

          ),
          SizedBox(width: 4),
          FilterChip(
            selected: mapModel.hammockSelcted,
            label: Text('Hammock', style: TextStyle(color: mapModel.hammockSelcted ? Colors.white : Colors.black),),
            onSelected: (value) => mapModel.onFilterChipSelected(value, CampFeature.Hammock),
            backgroundColor: Colors.white,
            selectedColor: Theme.of(context).primaryColor,
            checkmarkColor: Colors.white,
            elevation: 1,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],),
    );
  }
}