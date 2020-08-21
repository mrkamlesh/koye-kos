import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/camp.dart';
import '../providers.dart';
import 'camp_detail.dart';


class OpenContainerCamp extends StatelessWidget {
  final Camp camp;
  final Widget closedScreen;
  OpenContainerCamp(this.camp, {@required this.closedScreen});
  // TODO: fix widgets rebuilding during animation, likely cause for poor performance

  @override
  Widget build(BuildContext context) {
    return Consumer((context, watch) {
      //final firestore = watch(firestoreService);

      return OpenContainer(
        closedColor: Colors.transparent,
        closedShape: const RoundedRectangleBorder(),
        closedElevation: 0,
        openElevation: 0,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return ProviderScope(
            overrides: [
              campProvider.overrideWithValue(camp),
              favoritedProvider.overrideWithValue(false) // TODO
            ],
            child: closedScreen,
          );
        },
        openBuilder: (BuildContext context, VoidCallback _) {
          return ProviderScope(
            overrides: [
              campProvider.overrideWithValue(camp),
              favoritedProvider.overrideWithValue(false) // TODO
            ],
            child: CampDetailScreen(),
          );
        },
      );
    });
  }
}
