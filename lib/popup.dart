import 'package:firebase_auth/firebase_auth.dart';
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
              _buildImage(_camp.imageUrl),
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
    var _path = path;

    // hack to show image. TODO: firebase firestore impl for image retrieval
    if (Foundation.kDebugMode) {
      _path = 'images/spot_1_small.jpg';
    }

    return Image.asset(
      _path,
      width: 240,
      height: 160,
      fit: BoxFit.cover,
    );
  }
}
