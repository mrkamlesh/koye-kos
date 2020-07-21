import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'models.dart';

class CampDetailScreen extends StatelessWidget {
  final Camp _camp;
  CampDetailScreen(this._camp);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Camp'),
      ),
      body: Center(
        child: RaisedButton(
          child: Text('Delete camp',
            style: TextStyle(color: Colors.white),
          ),
          color: Colors.red,
          onPressed: () {
            print(_camp);
            print(_camp.id);
            firestoreService.deleteCamp(_camp).then((value) {
              Navigator.pop(context);
            });
          },
        ),
      ),
    );
  }
}
