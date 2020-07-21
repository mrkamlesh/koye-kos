import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'models.dart';

class CampDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final camp = Provider.of<Camp>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Camp'),
      ),
      body: Center(
        child: RaisedButton(
          child: Text(
            'Delete camp',
            style: TextStyle(color: Colors.white),
          ),
          color: Colors.red,
          onPressed: () {
            print(camp);
            print(camp.id);
            firestoreService.deleteCamp(camp).then((value) {
              Navigator.pop(context);
            });
          },
        ),
      ),
    );
  }
}
