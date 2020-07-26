import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'map_detail.dart';
import 'models.dart';

class CampDetailScreen extends StatelessWidget {
  final Camp camp;
  CampDetailScreen({this.camp});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
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
              RatingViewWidget(score: camp.score, ratings: camp.ratings),
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

class ImageList extends StatelessWidget {
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
          return Container(
            width: 340,
            // insert right padding to all but the last list item
            padding: !last ? EdgeInsets.only(right: 2) : null,
            child: MarkerCachedImage(
              camp.imageUrls[index],
              onTapCallback: (ImageProvider provider) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => Gallery(provider: provider),),);
              },
            ),
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
    return Container(
      child: PhotoView(
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 1.8,
        imageProvider: provider,
      ),
    );
  }
}
