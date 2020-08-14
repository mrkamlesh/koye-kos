import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/camp.dart';
import '../models/user.dart';
import '../services/db.dart';
import 'camp_detail.dart';


class OpenContainerCamp extends StatelessWidget {
  final Camp camp;
  final Widget closedScreen;
  OpenContainerCamp(this.camp, {@required this.closedScreen});
  // TODO: fix widgets rebuilding during animation, likely cause for poor performance

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final String userId = context.select((User user) => user.id);

    return OpenContainer(
      closedColor: Colors.transparent,
      closedShape: const RoundedRectangleBorder(),
      closedElevation: 0,
      openElevation: 0,
      closedBuilder: (BuildContext context, VoidCallback openContainer) {
        return MultiProvider(
          providers: [
            StreamProvider<Camp>(
              create: (_) => firestoreService.getCampStream(camp.id),
              initialData: camp,
            ),
            StreamProvider<bool>(
              create: (_) =>
                  firestoreService.campFavoritedStream(userId, camp.id),
              initialData: false,
            ),
          ],
          child: closedScreen,
        );
      },
      openBuilder: (BuildContext context, VoidCallback _) {
        return MultiProvider(
          providers: [
            StreamProvider<Camp>(
              create: (_) => firestoreService.getCampStream(camp.id),
              initialData: camp,
            ),
            StreamProvider<bool>(
              create: (_) =>
                  firestoreService.campFavoritedStream(userId, camp.id),
              initialData: false,
            ),
          ],
          child: CampDetailScreen(),
        );
      },
    );
  }
}
