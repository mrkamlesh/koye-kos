import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/auth.dart';
import 'package:koye_kos/db.dart';
import 'package:koye_kos/map.dart';
import 'package:provider/provider.dart';

import 'models.dart';

void main() => runApp(Application());

class Application extends StatefulWidget {
  @override
  _ApplicationState createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.currentUser().then((value) {
      if (value == null) {
        AuthService.signInAnonymously();
      }
    });

    return MultiProvider(
      providers: [
        StreamProvider<FirebaseUser>(
          create: (_) => FirebaseAuth.instance.onAuthStateChanged,
          lazy: false,
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService.instance,
        ),
      ],
      child: MaterialApp(
        title: 'Køye Kos',
        home: Scaffold(
          appBar: AppBar(
            title: Text('Køye Kos'),
            actions: [
              /* SignInWidget(),*/
            ],
          ),
          body: HammockMap(),
        ),
      ),
    );
  }
}
