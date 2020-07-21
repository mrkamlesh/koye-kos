import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong/latlong.dart';

import 'add_camp.dart';
import 'camp_detail.dart';
import 'db.dart';
import 'models.dart';
import 'utils.dart';

class MarkerBottomSheet extends StatelessWidget {
  final Camp _camp;
  MarkerBottomSheet(this._camp);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);

    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 24,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CampDetailScreen(
                    _camp), // Probably should use some provider approach here?
              ));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _camp.imageUrls.length,
                itemBuilder: (context, index) {
                  bool last = _camp.imageUrls.length == index + 1;
                  return Container(
                    // insert right padding to all but the last list item
                    padding: !last ? EdgeInsets.only(right: 2) : null,
                    child: SizedBox(
                      width: 120,
                      child: MarkerImage(_camp.imageUrls[index]),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                  'Location: ${_camp.location.toReadableString(precision: 4, separator: ', ')}'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Rating: ${_camp.score} (${_camp.ratings})'),
                StreamBuilder<bool>(
                    stream: firestoreService.campFavoritedStream(
                        user.uid, _camp.id),
                    builder: (context, snapshot) {
                      bool isFavorited = snapshot.data ?? false;
                      return IconButton(
                        icon: isFavorited
                            ? Icon(Icons.star)
                            : Icon(Icons.star_border),
                        onPressed: () {
                          firestoreService.setFavorited(user.uid, _camp.id,
                              favorited: !isFavorited);
                        },
                      );
                    }),
              ],
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_camp.description),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('By: ${_camp.creatorName}'),
            )
          ],
        ),
      ),
    );
  }
}

class MarkerImage extends StatelessWidget {
  final String _imagePath;

  MarkerImage(this._imagePath);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return FutureBuilder(
        future: firestoreService.getCampImage(_imagePath),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data,
              fit: BoxFit.cover,
            );
          } else if (snapshot.hasError) {
            return Text('Error loading image');
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
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
