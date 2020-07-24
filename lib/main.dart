import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth.dart';
import 'db.dart';
import 'map.dart';


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
        initialRoute: '/',
        routes: {
          '/': (context) => Home(),
        },
        theme: ThemeData.from(
          colorScheme: const ColorScheme.light(),
        ).copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
            },
          ),
        ),
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Køye Kos'),
      ),
      body: HammockMap(),
    );
  }
}

