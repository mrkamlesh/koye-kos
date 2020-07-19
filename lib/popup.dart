import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' as Foundation;
import 'package:flutter/material.dart';
import 'package:koye_kos/db.dart';
import 'package:provider/provider.dart';
import 'models.dart';

class CampMarkerPopup extends StatelessWidget {
  final Camp _camp;

  CampMarkerPopup(this._camp);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(
        context); // uid should be provided automatically by the db, eventually

    return Card(
      semanticContainer: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      elevation: 24,
      child: InkWell(
        child: Container(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 160,
                child: _buildImage(_camp.imageUrl),  // FIXME: seems to be rebuilt on map pan
              ),
              Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                        'Location: ${_camp.location.latitude.toStringAsFixed(4)}'
                            ' / ${_camp.location.longitude.toStringAsFixed(4)}'),
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
                                  firestoreService.setFavorited(
                                      user.uid, _camp.id,
                                      favorited: !isFavorited);
                                },
                              );
                            }),
                      ],
                    ),
                    Divider(),
                    Text(_camp.description),
                    Text('By: ${_camp.creatorName}')
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () => print('clicked'),
      ),
    );
  }

  static Widget _buildImage(String path) {
    return FutureBuilder(
        future: FirebaseStorage.instance.ref().child(path).getData(1000000),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data,
              fit: BoxFit.cover,
            );
          } else if (snapshot.hasError) {
            return Text('Error loading image: ${snapshot.error}');
          } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Loading image...'),
                ),
              ],
            ),
          );
          }
        });
  }
}
