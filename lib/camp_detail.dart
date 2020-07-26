import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

import 'db.dart';
import 'map_detail.dart';
import 'models.dart';

class CampDetailScreen extends StatelessWidget {
  final Camp camp;
  CampDetailScreen({this.camp});

  @override
  Widget build(BuildContext context) {
    return Provider<Camp>.value(
        value: camp,
        builder: (context, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Camp'),
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ImageList(),
                CampInfo(),
                DeleteCamp(),
              ],
            ),
          );
        });
  }
}

class RatingWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final camp = Provider.of<Camp>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: Text('${camp.score}'),
        ),
        SmoothStarRating(
          rating: camp.score,
          color: Colors.amber,
          borderColor: Colors.amber,
          onRated: (rating) {
            firestoreService.updateRating(camp, user, rating);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text('(${camp.ratings})'),
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
              RatingWidget(),
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
