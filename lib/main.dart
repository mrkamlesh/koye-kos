import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/auth.dart';
import 'package:koye_kos/map.dart';
import 'package:provider/provider.dart';

void main() => runApp(Application());

class Application extends StatefulWidget {
  @override
  _ApplicationState createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<FirebaseUser>(
            create: (_) => FirebaseAuth.instance.onAuthStateChanged
        )
      ],
      child: MaterialApp(
        title: 'Køye Kos',
        home: Scaffold(
          appBar: AppBar(
            title: Text('Køye Kos'),
            actions: [
              SignInWidget(),
            ],
          ),
          body: Center(
            child: Container(
              child: HammockMap(),
            ),
          ),
        ),
      ),
    );
  }
}
