import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/camp.dart';
import '../providers.dart';
import 'camp_detail.dart';

/*
* It is important to note that the OpenContainer widget must be used in a
* context with a Navigator. When it transitions from the closed widget to
* the open widget, it pushes a new PageRoute onto its closest ancestor
* Navigator. It then grows the open widget to fill the entire size of this
* Navigator. Most Navigators are full-screen, but don’t have to be.
*/
class OpenContainerCamp extends StatelessWidget {
  final Widget closedScreen;
  final Widget openScreen;
  OpenContainerCamp({@required this.closedScreen, @required this.openScreen});
  // TODO: fix widgets rebuilding during animation, likely cause for poor performance

  @override
  Widget build(BuildContext context) {
    print('build opc');
    return Consumer((context, watch) {
      //final firestore = watch(firestoreService);
      final Camp camp = watch(campProvider);
      final bool favorited = watch(favoritedProvider);
      return OpenContainer(
        closedColor: Colors.transparent,
        closedShape: const RoundedRectangleBorder(),
        closedElevation: 0,
        openElevation: 0,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          print('closedbuilder');
          return closedScreen;
        },
        openBuilder: (BuildContext context, VoidCallback _) {
          print('openbuilder');
          return ProviderScope(
              overrides: [
                campProvider.overrideWithValue(camp),
                favoritedProvider.overrideWithValue(favorited),
              ],
              child: openScreen);
        },
      );
    });
  }
}
