import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong/latlong.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

import 'add_camp.dart';
import 'db.dart';
import 'models.dart';
import 'utils.dart';

class MarkerBottomSheet extends StatelessWidget {
  final Camp camp;
  MarkerBottomSheet({this.camp});

  @override
  Widget build(BuildContext context) {
    return Provider<Camp>.value(
        value: camp,
        builder: (context, child) {
          // Add a nice linear drop shadow behind card (from transparent to greY)
          return Card(
            clipBehavior: Clip.antiAliasWithSaveLayer, // for rounded corners
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 120, // restrict image height
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: camp.imageUrls.length,
                    itemBuilder: (context, index) {
                      bool last = camp.imageUrls.length == index + 1;
                      return Container(
                        // insert right padding to all but the last list item
                        padding: !last ? EdgeInsets.only(right: 2) : null,
                        child: SizedBox(
                          width: 220,
                          child: MarkerCachedImage(camp.imageUrls[index]),
                        ),
                      );
                    },
                  ),
                ), // Image view
                Padding(
                  // Rest of camp description / rating view
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          RatingViewWidget(
                              score: camp.score, ratings: camp.ratings),
                          FavoriteWidget(),
                        ],
                      ),
                      Text(camp.description),
                      Divider(),
                      Text('By: ${camp.creatorName ?? 'Anonymous'}'),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }
}

class FavoriteWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);
    final camp = Provider.of<Camp>(context);

    return StreamBuilder<bool>(
        stream: firestoreService.campFavoritedStream(user.uid, camp.id),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          bool isFavorited = snapshot.data ?? false;
          return IconButton(
            icon: isFavorited
                ? Icon(Icons.favorite, color: Colors.redAccent)
                : Icon(Icons.favorite_border),
            onPressed: () {
              firestoreService.setFavorited(user.uid, camp.id,
                  favorited: !isFavorited);
            },
          );
        });
  }
}

class RatingViewWidget extends StatelessWidget {
  final double score;
  final int ratings;

  RatingViewWidget({this.score, this.ratings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: Text('$score'),
        ),
        SmoothStarRating(
          isReadOnly: true,
          rating: score,
          color: Colors.amber,
          borderColor: Colors.amber,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text('($ratings)'),
        ),
      ],
    );
  }
}

class MarkerCachedImage extends StatefulWidget {
  final String _imageUrl;
  MarkerCachedImage(this._imageUrl);

  @override
  _MarkerCachedImageState createState() => _MarkerCachedImageState();
}

class _MarkerCachedImageState extends State<MarkerCachedImage> with AutomaticKeepAliveClientMixin{

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CachedNetworkImage(
      imageUrl: widget._imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) {
        return Container(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        );
      },
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class PointBottomSheet extends StatelessWidget {
  final LatLng _point;
  PointBottomSheet(this._point);

  @override
  Widget build(BuildContext context) {
    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 24,
      child: InkWell(
        child: Container(
          child: ListTile(
              leading: Icon(Icons.location_on, color: Colors.red),
              title:
                  Text(_point.toReadableString(precision: 4, separator: ', ')),
              trailing: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  color: Colors.blue,
                  textColor: Colors.white,
                  child: Text('Add camp'),
                  onPressed: () {
                    //Navigator.pop(context);  // removes bottomsheet
                    Navigator.push(
                            context,
                            MaterialPageRoute<bool>(
                                builder: (context) => AddCampScreen(_point)))
                        .then((bool campAdded) {
                      if (campAdded ?? false) {
                        Navigator.pop(context);
                        Scaffold.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(
                              SnackBar(content: Text('Camp added!')));
                      }
                    });
                  })),
        ),
      ),
    );
  }
}
