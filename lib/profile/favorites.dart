import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/map/map.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../utils.dart';
import '../camp/camp_utils.dart';
import '../services/db.dart';
import '../map/map_detail.dart';

class FavoritedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final String userId = context.select((FirebaseUser user) => user.uid);
    return StreamBuilder<List<Favorite>>(
        stream: firestoreService.campIdsFavoritedStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.isNotEmpty) {
            return FavoriteListView(favorites: snapshot.data);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text('Loading favorites...'),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              child: Center(
                child: Text(
                    'You have no favorites. Tap the heart icon on a camp to add one.'),
              ),
            );
          }
        });
  }
}

class FavoriteListView extends StatelessWidget {
  final List<Favorite> favorites;
  FavoriteListView({
    @required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final String userId = context.select((FirebaseUser user) => user.uid);

    return StreamBuilder<List<Camp>>(
      stream: firestoreService
          .getCampsStream(favorites.map((f) => f.campId).toList()),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<Camp> camps = snapshot.data; // un-ordered list of maps
          return ListView.builder(
            itemCount: camps.length,
            itemBuilder: (_, index) {
              final Camp camp = camps[index];
              return MultiProvider(
                providers: [
                  StreamProvider<Camp>(
                    create: (_) => firestoreService.getCampStream(camp.id),
                    initialData: camp,
                  ),
                  StreamProvider<bool>(
                    create: (_) =>
                        firestoreService.campFavoritedStream(userId, camp.id),
                    initialData: true,
                  ),
                ],
                child: OpenContainerCamp(camp,
                    closedScreen: FavoriteListItem(camp: camps[index])),
              );
            },
          );
        } else {
          return Container(
            child: Center(
              child: Text('Error fetching camp data...'),
            ),
          );
        }
      },
    );
  }
}

class FavoriteListItem extends StatelessWidget {
  final Camp camp;
  const FavoriteListItem({@required this.camp});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final String userId = context.select((FirebaseUser user) => user.uid);
    return InkWell(
      child: Container(
        height: 100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: MarkerCachedImage(camp.imageUrls.first),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      '${camp.location.toReadableString(precision: 2, separator: ', ')}. ${camp.score} (${camp.ratings})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                      ),
                    ),
                    Text(
                      'Description: ${camp.description}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    Text(
                      '- ${camp.creatorName}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w300,
                        fontSize: 13.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      firestoreService.setFavorited(userId, camp.id,
                          favorited: false);
                      // TODO: add undo
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
