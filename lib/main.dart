import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'camp/camp_detail.dart';
import 'models/user.dart';
import 'profile/profile.dart';
import 'providers.dart';
import 'services/auth.dart';
import 'services/db.dart';
import 'map/map.dart';

void main() {
  runApp(ProviderScope(child: Application()));
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
            return MyApp(
              firestoreBuilder: (_, uid) => FirestoreService(uid: uid),
            );
          }
          return Material(
            child: CircularProgressIndicator(),
          );
        });
  }
}

final _userSnapshot = ScopedProvider<AsyncSnapshot<UserModel>>((ref) {
  throw UnimplementedError();
});

class MyApp extends StatelessWidget {
  final FirestoreService Function(BuildContext context, String uid)
      firestoreBuilder;

  const MyApp({this.firestoreBuilder});

  @override
  Widget build(BuildContext context) {
    return AuthWidgetBuilder(
      firestoreBuilder: firestoreBuilder,
      builder: (BuildContext context, AsyncSnapshot<UserModel> userSnapshot) {
        return MaterialApp(
          title: 'Køye Kos',
          routes: {
            //'/': (context) => Home(),
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
          home: ProviderScope(
              overrides: [_userSnapshot.overrideWithValue(userSnapshot)],
              child: StartupView()),
        );
      },
    );
  }
}

class StartupView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer((context, watch) {
      final userSnapshot = watch(_userSnapshot);
      if (userSnapshot.connectionState == ConnectionState.active) {
        return userSnapshot.hasData ? Home() : SplashScreen();
      }
      return Material(
        child: CircularProgressIndicator(),
      );
    });
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Container(
        color: Colors.green,
      ),
    );
  }
}

class AuthWidgetBuilder extends StatelessWidget {
  final Widget Function(BuildContext, AsyncSnapshot<UserModel>) builder;
  final FirestoreService Function(BuildContext context, String uid) firestoreBuilder;

  const AuthWidgetBuilder(
      {Key key, @required this.builder, @required this.firestoreBuilder})
      : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Consumer((context, watch) {
      final auth = watch(authProvider);
      return StreamBuilder<UserModel>(
        stream: auth.userStream,
        builder: (BuildContext context, AsyncSnapshot<UserModel> snapshot) {
          final UserModel user = snapshot.data;
          if (user != null) {
            return ProviderScope(
              overrides: [
                userProvider.overrideWithValue(user),
                firestoreService
                    .overrideWithValue(firestoreBuilder(context, user.id))
              ],
              child: builder(context, snapshot),
            );
          }
          return builder(context, snapshot);
        },
      );
    });
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
