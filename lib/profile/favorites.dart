import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:provider/provider.dart';

import '../models/camp.dart';
import '../models/user.dart';
import '../utils.dart';
import '../camp/camp_utils.dart';
import '../services/db.dart';
import '../map/map_detail.dart';

class FavoritedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return StreamBuilder<List<Favorite>>(
        stream: firestoreService.campIdsFavoritedStream(),
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

    return StreamBuilder<List<Camp>>(
      stream: firestoreService
          .getCampsStream(favorites.map((f) => f.campId).toList()),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<Camp> camps = snapshot.data; // un-ordered list of maps
          return ImplicitlyAnimatedList<Camp>(
            items: camps,
            areItemsTheSame: (a, b) => a.id == b.id,
            itemBuilder: (_, animation, item, index) {
              return SizeFadeTransition(
                animation: animation,
                child: OpenContainerCamp(item,
                      closedScreen: FavoriteListItem(camp: item)),
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
                      firestoreService.setFavorited(camp.id,
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
