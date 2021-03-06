import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:koye_kos/models/favorite.dart';
import 'package:provider/provider.dart';

import '../models/camp.dart';
import '../utils.dart';
import '../camp/camp_utils.dart';
import '../map/map_detail.dart';
import 'providers/favorite_provider.dart';

class FavoritedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final favoriteModel = Provider.of<FavoriteModel>(context);
    return StreamBuilder<List<Favorite>>(
        stream: favoriteModel.favoriteCampIdsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.isNotEmpty) {
            return FavoriteListView();
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
  @override
  Widget build(BuildContext context) {
    final favoriteModel = Provider.of<FavoriteModel>(context);
    return StreamBuilder<List<Camp>>(
        stream: favoriteModel.favoriteCampsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<Camp> camps = snapshot.data;
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
          }
        });
  }
}

class FavoriteListItem extends StatelessWidget {
  final Camp camp;
  const FavoriteListItem({@required this.camp});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        height: 100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: CampCachedImage(
                camp.thumbnailUrls.first,
                key: ValueKey(camp.id),
              ),
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
                      '${camp.description}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: '${camp.score}',
                          ),
                          WidgetSpan(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                          TextSpan(text: '(${camp.ratings})'),
                        ],
                      ),
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
                      context.read<FavoriteModel>().unfavorite(camp.id);
                      Scaffold.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          content: Text('Camp unfavorited!'),
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed:
                                context.read<FavoriteModel>().undoFavorite,
                          ),
                        ));
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
