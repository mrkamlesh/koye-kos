import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/auth.dart';
import 'favorites.dart';

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Provider.of<AuthProvider>(context);
    return auth.status == AuthStatus.Authenticated ? AccountView() : SignUpView();
  }
}

class SignUpView extends StatefulWidget {
  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  bool signingIn = false;
  @override
  Widget build(BuildContext context) {
    //final AuthService authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: signingIn
              ? CircularProgressIndicator()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                    ),
                    Container(
                      child: Icon(
                        Icons.person_pin,
                        size: 100,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Container(
                        child: Text(
                          'Select sign up method',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                    ),
                    Divider(),
                    RaisedButton(
                      child: Text('GOOGLE'),
                      color: Colors.red,
                      onPressed: () async {
                        setState(() {
                          signingIn = true;
                        });
                        /*authService.signInWithGoogle().then((signedIn) {
                          if (!signedIn) {
                            setState(() {
                              signingIn = false;
                            });
                          }
                        });*/
                      },
                    )
                  ],
                ),
        ),
      ),
    );
  }
}

class AccountView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Account'),
          actions: [
            FlatButton(
              onPressed: () => AuthService.instance.signOut(),
              child: Text(
                'Log out',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Icon(
                Icons.person,
              ),
              Icon(
                Icons.favorite,
                color: Colors.red,
              ),
              Icon(
                Icons.star,
                color: Colors.amber,
              ),
              FaIcon(
                FontAwesomeIcons.mapMarkedAlt,
                color: Colors.green,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProfileWidget(),
            FavoritedView(),
            RatedView(),
            CreatedView(),
          ],
        ),
      ),
    );
  }
}

class RatedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Icon(Icons.star),
    );
  }
}

class CreatedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: FaIcon(FontAwesomeIcons.mapMarkedAlt)),
    );
  }
}

class ProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    return Consumer<UserModel>(
      builder: (context, user, child) {
        if (user == null || user.name == null) {
          return Container(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.photoUrl,
                      ),
                    ),
                  ),
                  Text(
                    '${user.name}',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  Text('${user.email}',
                      style: Theme.of(context).textTheme.headline6),
                  Divider(height: 40),
                  Expanded(
                    child: Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: RaisedButton(
                        child: Text(
                          'Log out',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Theme.of(context).primaryColor,
                        onPressed: () async => await authService.signOut(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
