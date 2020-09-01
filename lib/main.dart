import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'camp/camp_detail.dart';
import 'map/map_model.dart';
import 'models/user.dart';
import 'profile/profile.dart';
import 'profile/profile_model.dart';
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
              ChangeNotifierProvider<Auth>(
                create: (_) => Auth(),
                lazy: false,
              ),
              ProxyProvider<Auth, FirestoreService>(
                // TODO: create() ?
                update: (_, auth, __) => FirestoreService(user: auth.user),
              )
            ],
            builder: (context, child) {
              return context.watch<Auth>().status == AuthStatus.Unauthenticated
                  ? LoadingScreen()
                  : MyApp();
            },
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
    return MaterialApp(
      title: 'Køye Kos',
      initialRoute: '/',
      routes: {
        '/': (context) => Home(),
        '/profile': (context) =>
            ChangeNotifierProxyProvider2<Auth, FirestoreService, ProfileModel>(
              create: (context) => ProfileModel(
                auth: context.read<Auth>(),
                firestore: context.read<FirestoreService>(),
              ),
              update: (context, auth, firestore, profileModel) => profileModel
                ..setAuth(auth)
                ..setFirestore(firestore),
              child: Profile(),
            ),
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
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
        stream: Connectivity().onConnectivityChanged,
        builder: (context, snapshot) {
          //print('------snap: $snapshot');
          if (snapshot.hasData) {
            if (snapshot.data == ConnectivityResult.none) {
              return ConnectivityInfo();
            }
            context.watch<Auth>().initialize();
            return SplashScreen();
          }

          return FutureBuilder(
              future: Connectivity().checkConnectivity(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    snapshot?.data != ConnectivityResult.none) {
                  return SplashScreen();
                }
                return ConnectivityInfo();
              });
        });
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Køye Kos!',
                style: TextStyle(fontSize: 40),
              ),
              SizedBox(
                height: 20,
              ),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class ConnectivityInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            'An internet connection is necessary for first time setup.',
            style: TextStyle(fontSize: 20),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
