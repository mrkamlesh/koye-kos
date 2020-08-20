import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'camp/camp_detail.dart';
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
    return MultiProvider(
      providers: [
        Provider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MyApp(
        firestoreBuilder: (_, uid) => FirestoreService(uid: uid),
      ),
    );
  }
}

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
          home: Consumer<AuthProvider>(
            builder: (_, value, __) {
              if (userSnapshot.connectionState == ConnectionState.active) {
                return userSnapshot.hasData ? Home() : SplashScreen();
              }
              return Material(
                child: CircularProgressIndicator(),
              );
            },
          ),
        );
      },
    );
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
  const AuthWidgetBuilder(
      {Key key, @required this.builder, @required this.firestoreBuilder})
      : super(key: key);
  final Widget Function(BuildContext, AsyncSnapshot<UserModel>) builder;
  final FirestoreService Function(BuildContext context, String uid)
      firestoreBuilder;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthProvider>(context, listen: false);
    return StreamBuilder<UserModel>(
      stream: authService.userStream,
      builder: (BuildContext context, AsyncSnapshot<UserModel> snapshot) {
        final UserModel user = snapshot.data;
        if (user != null) {
          /*
          * For any other Provider services that rely on user data can be
          * added to the following MultiProvider list.
          * Once a user has been detected, a re-build will be initiated.
           */
          return MultiProvider(
            providers: [
              Provider<UserModel>.value(value: user),
              Provider<FirestoreService>(
                create: (context) => firestoreBuilder(context, user.id),
              ),
            ],
            child: builder(context, snapshot),
          );
        }
        return builder(context, snapshot);
      },
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
