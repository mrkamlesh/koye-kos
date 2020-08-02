import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../utils.dart';
import '../map/camp_detail.dart';
import '../services/db.dart';
import '../map/map_detail.dart';


class FavoritedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final String userId = context.select((User user) => user.id);
    return StreamBuilder<List<String>>(
        stream: firestoreService.campIdsFavoritedStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.isNotEmpty) {
            return FavoriteListView(campIds: snapshot.data);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
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
        }
    );

  }
}

class FavoriteListView extends StatelessWidget {
  final List<String> campIds;
  const FavoriteListView({
    @required this.campIds,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return StreamBuilder<List<Camp>>(
      stream: firestoreService.getCampsStream(campIds),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<Camp> camps = snapshot.data;
          return ListView.builder(
            itemCount: camps.length,
            itemBuilder: (_, index) {
              return FavoriteListItem(camp: camps[index]);
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
    final String userId = context.select((User user) => user.id);
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: MarkerCachedImage(camp.imageUrls.first),
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${camp.location}', style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,),),
                Text('${camp.description}'),
                Text('${camp.creatorName}'),
              ],
            ),
          ),
          Center(
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
        ],
      ),
    );

    /*ListTile(
        contentPadding: EdgeInsets.all(0),
        title: Text(
            '${camp.location.toReadableString(precision: 4, separator: ', ')}'),
        subtitle: Text('${camp.description}'),
        leading: Container(
          width: 80,
          child: MarkerCachedImage(camp.imageUrls.first),
        ),
        trailing: IconButton(
            icon: Icon(
              Icons.favorite,
              color: Colors.red,
            ),
            onPressed: () {
              firestoreService.setFavorited(userId, camp.id,
                  favorited: false);
              // TODO: add undo
            }),
        onTap: () {
          // FIXME: This is messy. Also use openContainer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultiProvider(
                providers: [
                  StreamProvider<Camp>(
                    create: (_) =>
                        firestoreService.getCampStream(camp.id),
                    initialData: camp,
                  ),
                  StreamProvider<bool>(
                    create: (_) => firestoreService
                        .campFavoritedStream(userId, camp.id),
                    initialData: true,
                  ),
                ],
                child: CampDetailScreen(),
              ),
            ),
          );
        });*/
  }
}
