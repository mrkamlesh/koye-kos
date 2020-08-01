import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/camp_detail.dart';
import 'package:koye_kos/profile.dart';
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
    AuthService.instance.currentUser.then((value) {
      if (value == null) {
        AuthService.instance.signInAnonymously();
      }
    });

    return MultiProvider(
      providers: [
        StreamProvider<FirebaseUser>.value(
          value: FirebaseAuth.instance.onAuthStateChanged,
          lazy: false,
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService.instance,
        ),
        Provider<AuthService>(
          create: (_) => AuthService.instance,
        ),
      ],
      child: MaterialApp(
        title: 'Køye Kos',
        initialRoute: '/',
        routes: {
          '/': (context) => Home(),
          '/profile': (context) => Profile(),
          '/detail': (context) => CampDetailScreen(),
        },
        theme: ThemeData().copyWith(
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
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: HammockMap(),
    );
  }
}
