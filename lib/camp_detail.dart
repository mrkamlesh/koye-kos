import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'map_detail.dart';
import 'models.dart';

class CampDetailScreen extends StatelessWidget {
  CampDetailScreen();

  @override
  Widget build(BuildContext context) {
    final camp = Provider.of<Camp>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Camp'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageList(),
          Center(
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
          ),
        ],
      ),
    );
  }
}

class ImageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);
    final camp = Provider.of<Camp>(context);

    return Column(
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
                  width: 120,
                  child: MarkerCachedImage(camp.imageUrls[index]),
                ),
              );
            },
          ),
        ),
        Padding(
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
        )
      ],
    );
  }
}
