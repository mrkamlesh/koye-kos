import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:provider/provider.dart';

import '../models/camp.dart';
import '../services/db.dart';
import 'camp_detail.dart';
import 'providers/camp_model.dart';

class OpenContainerCamp extends StatelessWidget {
  final Camp camp;
  final Widget closedScreen;
  OpenContainerCamp(this.camp, {@required this.closedScreen});
  // TODO: fix widgets rebuilding during animation, likely cause for poor performance
  // TODO: OpenContainer looks like shit, change it

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedColor: Colors.transparent,
      closedShape: const RoundedRectangleBorder(),
      closedElevation: 0,
      openElevation: 0,
      closedBuilder: (_, __) {
        return ChangeNotifierProxyProvider2<Auth, FirestoreService,
            CampModel>(
          create: (context) => CampModel(
              auth: context.read<Auth>(),
              firestore: context.read<FirestoreService>(),
              camp: camp),
          update: (_, auth, firestore, campModel) => campModel
            ..setAuth(auth)
            ..setFirestore(firestore),
          child: closedScreen,
        );
      },
      openBuilder: (_, __) {
        return ChangeNotifierProxyProvider2<Auth, FirestoreService,
            CampModel>(
          create: (context) => CampModel(
              auth: context.read<Auth>(),
              firestore: context.read<FirestoreService>(),
              camp: camp),
          update: (_, auth, firestore, campModel) => campModel
            ..setAuth(auth)
            ..setFirestore(firestore),
          child: CampDetailScreen(),
        );
      },
    );
  }
}
