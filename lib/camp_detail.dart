import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:koye_kos/star_rating.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'map_detail.dart';
import 'models.dart';

class CampDetailScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Camp'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageList(),
            CampInfo(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: UserRatingWidget(),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: DeleteCamp(),
            ),
          ],
        ),
      ),
    );
  }
}

class UserRatingWidget extends StatefulWidget {
  @override
  _UserRatingWidgetState createState() => _UserRatingWidgetState();
}

class _UserRatingWidgetState extends State<UserRatingWidget> {
  double _score = 0;

  @override
  void initState() {
    final camp = Provider.of<Camp>(context, listen: false);
    final user = Provider.of<FirebaseUser>(context, listen: false);
    Provider.of<FirestoreService>(context, listen: false)
        .getUserCampRating(user.uid, camp.id)
        .then((double score) {
      setState(() {
        _score = score;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final camp = Provider.of<Camp>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);
    return Column(
      children: [
        Text(
          'Rate',
          style: Theme.of(context).textTheme.headline6,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: StarRating(
            key: UniqueKey(),
            rating: _score,
            size: 50,
            color: Colors.amber,
            borderColor: Colors.amber,
            onRated: (rating) {
              firestoreService.updateRating(camp, user, rating);
              setState(() {
                _score = rating;
              });
            },
          ),
        ),
      ],
    );
  }
}

class RatingView extends StatelessWidget {
  final double score;
  final int ratings;

  RatingView({this.score, this.ratings});

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

class CampInfo extends StatelessWidget {
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
              RatingView(
                score: camp.score,
                ratings: camp.ratings,
              ),
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

class ImageList extends StatefulWidget {
  @override
  _ImageListState createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  final Map<int, ImageProvider> images = HashMap();
  @override
  Widget build(BuildContext context) {
    final camp = Provider.of<Camp>(context);
    return Container(
      height: 200, // restrict image height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: camp.imageUrls.length,
        itemBuilder: (context, index) {
          bool last = camp.imageUrls.length == index + 1;
          return GestureDetector(
            child: Container(
              width: 340,
              // insert right padding to all but the last list item
              padding: !last ? EdgeInsets.only(right: 2) : null,
              child: MarkerCachedImage(
                camp.imageUrls[index],
                onLoadCallback: (ImageProvider provider) {
                  images[index] = provider;
                },
              ),
            ),
            onTap: () {
              // TODO: make gallery out of images
              if (!images.containsKey(index)) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Gallery(provider: images[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Gallery extends StatelessWidget {
  final ImageProvider provider;
  const Gallery({
    this.provider,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        child: PhotoView(
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 1.8,
          imageProvider: provider,
        ),
      ),
    );
  }
}

class DeleteCamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final camp = Provider.of<Camp>(context);
    return Center(
      child: RaisedButton(
        child: Text(
          'Delete camp',
          style: TextStyle(color: Colors.white),
        ),
        color: Colors.red,
        onPressed: () {
          firestoreService.deleteCamp(camp);
          Navigator.pop(context);
        },
      ),
    );
  }
}
