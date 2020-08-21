import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koye_kos/models/camp.dart';
import 'package:koye_kos/providers.dart';
import 'package:latlong/latlong.dart';

import '../camp/add_camp.dart';
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
    return Consumer((context, watch) {
      final camp = watch(campProvider);
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
    });
  }
}

class ImageListSmall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer((context, watch) {
      final Camp camp = watch(campProvider);
      print('imagelistsmall: $camp');
      final imageUrls = camp.imageUrls;
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
    });
  }
}

class FavoriteWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer((context, watch) {
      final isFavorited = watch(favoritedProvider);
      final campId = watch(campProvider).id;
      final firestore = watch(firestoreService);

      return IconButton(
        icon: isFavorited
            ? Icon(Icons.favorite, color: Colors.redAccent)
            : Icon(Icons.favorite_border),
        onPressed: () {
          firestore.setFavorited(campId,
              favorited: !isFavorited);
        },
      );
    });
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
        if (showDetails) Padding(
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
        if (showDetails) Padding(
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
