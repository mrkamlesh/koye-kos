import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/camp/providers/camp_model.dart';
import 'package:koye_kos/camp/providers/add_camp_model.dart';
import 'package:koye_kos/camp/add_camp.dart';
import 'package:koye_kos/camp/ui/feature_chips.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';
import 'package:koye_kos/ui/dialog.dart';
import 'package:provider/provider.dart';

import '../utils.dart';
import '../camp/star_rating.dart';

class MarkerBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer, // for rounded corners
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageListSmall(), // Image view
            CampDescription()
          ],
        ),
      ),
    );
  }
}

class CampDescription extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final camp = Provider.of<CampModel>(context).camp;
    return Padding(
      // Rest of camp description / rating view
      padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RatingViewSmall(score: camp.score, ratings: camp.ratings),
              FavoriteWidget(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: CampFeaturesWidget(camp.features),
          ),
          Text(camp.description),
          Divider(),
          Text('By: ${camp.creatorName ?? 'Anonymous'}'),
        ],
      ),
    );
  }
}

class ImageListSmall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls =
        context.select((CampModel campModel) => campModel.camp.thumbnailUrls);
    return Container(
      height: 120, // restrict image height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          bool last = imageUrls.length == index + 1;
          return Container(
            width: 220,
            // insert right padding to all but the last list item
            padding: !last ? EdgeInsets.only(right: 2) : null,
            child: CampCachedImage(imageUrls[index]),
          );
        },
      ),
    );
  }
}

class FavoriteWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final campModel = Provider.of<CampModel>(context);
    return IconButton(
      icon: campModel.favorited
          ? Icon(Icons.favorite, color: Colors.redAccent)
          : Icon(Icons.favorite_border),
      onPressed: campModel.toggleFavorited,
    );
  }
}

class RatingViewSmall extends StatelessWidget {
  final double score;
  final int ratings;
  final bool showDetails;

  RatingViewSmall({this.score, this.ratings, this.showDetails = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showDetails)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text('${score.toStringAsFixed(1)}'),
          ),
        StarRating(
          key: UniqueKey(),
          isReadOnly: true,
          rating: score,
          color: Colors.amber,
          borderColor: Colors.amber,
        ),
        if (showDetails)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text('($ratings)'),
          ),
      ],
    );
  }
}

class CampCachedImage extends StatefulWidget {
  final String _imageUrl;
  final Function(ImageProvider) onLoadCallback;
  CampCachedImage(this._imageUrl, {this.onLoadCallback, Key key}) : super(key: key);

  @override
  _CampCachedImageState createState() => _CampCachedImageState();
}

class _CampCachedImageState extends State<CampCachedImage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CachedNetworkImage(
      imageUrl: widget._imageUrl,
      imageBuilder: (context, imageProvider) {
        if (widget.onLoadCallback != null) widget.onLoadCallback(imageProvider);
        return Image(
          fit: BoxFit.cover,
          image: imageProvider,
        );
      },
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
  @override
  Widget build(BuildContext context) {
    final Point<double> point = Provider.of<Point<double>>(context);
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
                  Text(point.toReadableString(precision: 4, separator: ', ')),
              trailing: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  color: Colors.blue,
                  textColor: Colors.white,
                  child: Text('Add camp'),
                  onPressed: () {
                    if (context.read<Auth>().isAuthenticated)
                      kIsWeb
                      ? showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Web not supported'),
                              content: Text('Adding camp from web is currently not supported..'),
                            actions: [
                              FlatButton(
                                child: Text('Dismiss'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          );
                        },
                      )
                      : Navigator.push(
                          context,
                          MaterialPageRoute<bool>(
                            builder: (_) => ChangeNotifierProxyProvider2<Auth,
                                FirestoreService, AddModel>(
                              create: (context) => AddModel(
                                auth: context.read<Auth>(),
                                firestore: context.read<FirestoreService>(),
                                location: point,
                              ),
                              update: (_, auth, firestore, addModel) => addModel
                                ..setAuth(auth)
                                ..setFirestore(firestore),
                              child: AddCampScreen(),
                            ),
                          )).then((bool campAdded) {
                        if (campAdded ?? false) {
                          Navigator.pop(context);
                          Scaffold.of(context)
                            ..removeCurrentSnackBar()
                            ..showSnackBar(
                                SnackBar(content: Text('Camp added!')));
                        }
                      });
                    else
                      showDialog(
                        context: context,
                        builder: (context) {
                          return LogInDialog(
                            actionText: 'add a camp',
                          );
                        },
                      );
                  })),
        ),
      ),
    );
  }
}
