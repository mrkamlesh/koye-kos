import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong/latlong.dart';

import '../camp/add_camp.dart';
import '../services/db.dart';
import '../models/camp.dart';
import '../models/user.dart';
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
    final camp = Provider.of<Camp>(context);
    return Padding(
      // Rest of camp description / rating view
      padding: const EdgeInsets.all(8.0),
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
    final List<String> imageUrls = context.select((Camp camp) => camp.imageUrls);
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
            child: MarkerCachedImage(imageUrls[index]),
          );
        },
      ),
    );
  }
}

class FavoriteWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final String userId = context.select((User user) => user.id);
    final String campId = context.select((Camp camp) => camp.id);
    final bool isFavorited = Provider.of<bool>(context);

    return IconButton(
      icon: isFavorited
          ? Icon(Icons.favorite, color: Colors.redAccent)
          : Icon(Icons.favorite_border),
      onPressed: () {
        firestoreService.setFavorited(userId, campId,
            favorited: !isFavorited);
      },
    );
  }
}

class RatingViewSmall extends StatelessWidget {
  final double score;
  final int ratings;

  RatingViewSmall({this.score, this.ratings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
  final Function(ImageProvider) onLoadCallback;
  MarkerCachedImage(this._imageUrl, {this.onLoadCallback});

  @override
  _MarkerCachedImageState createState() => _MarkerCachedImageState();
}

class _MarkerCachedImageState extends State<MarkerCachedImage>
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
