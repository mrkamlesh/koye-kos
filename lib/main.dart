import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'camp/camp_detail.dart';
import 'map/map_model.dart';
import 'models/user.dart';
import 'profile/profile.dart';
import 'services/auth.dart';
import 'services/db.dart';
import 'map/map.dart';

void main() {
  runApp(Application());
}

class Application extends StatefulWidget {
  @override
  _ApplicationState createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>(
                create: (_) => AuthProvider(),
                lazy: false,
              ),
              ProxyProvider<AuthProvider, FirestoreService>(
                update: (_, auth, __) => FirestoreService(uid: auth.user.id),
              )
            ],
            child: MyApp(),
          );
        }
        return SplashScreen();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return StreamBuilder<UserModel>(
      stream: auth.userStream,
      builder: (_, snapshot) {
        final user = snapshot.data;
        return user == null
            ? SplashScreen()
            : MaterialApp(
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
              );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            'Welcome to Køye Kos!',
            style: TextStyle(fontSize: 40),
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
      body: ChangeNotifierProxyProvider<FirestoreService, MapModel>(
        create: (context) =>
            MapModel(firestore: context.read<FirestoreService>()),
        update: (_, firestore, mapModel) => mapModel..setFirestore(firestore),
        child: Map(),
      ),
    );
  }
}
