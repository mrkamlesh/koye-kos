import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:koye_kos/auth.dart';
import 'package:koye_kos/db.dart';
import 'package:koye_kos/main.dart';
import 'package:koye_kos/map_detail.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'utils.dart';

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final FirebaseUser user = Provider.of<FirebaseUser>(context);
    if (user == null || user.isAnonymous) {
      return SignUpView();
    }

    return StreamProvider<User>(
        create: (_) => firestoreService.getUserStream(user.uid),
        lazy: false,
        builder: (context, snapshot) {
          return AccountView();
        });
  }
}

class SignUpView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
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
                  await authService.signInWithGoogle();
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
    final AuthService authService = Provider.of<AuthService>(context);
    final User user = Provider.of<User>(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Account'),
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

class FavoritedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final String userId = context.select((User user) => user.id);
    //List<String> favoriteCamps = context.select(())
    return StreamBuilder<List<String>>(
      stream: firestoreService.campIdsFavoritedStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                CircularProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text('Loading favorites...'),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasData) {
          final List<String> campIds = snapshot.data;
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              return StreamBuilder<Camp>(
                  stream: firestoreService.getCampStream(campIds[index]),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final Camp camp = snapshot.data;
                      return ListTile(
                        title: Text('${camp.location.toReadableString(precision: 4, separator: ', ')}'),
                        subtitle: Text('${camp.description}'),
                        leading: Container(
                          width: 80,
                          height: 80,
                          child: MarkerCachedImage(camp.imageUrls.first),
                        ),
                        trailing: IconButton(
                            icon: Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              firestoreService.setFavorited(userId, camp.id,
                                  favorited: false);
                              // TODO: add undo
                            }),
                      );
                    } else {
                      return Container(
                        child: Center(
                          child: Text('No camp data'),
                        ),
                      );
                    }
                  }
              );
            },
          );
        } else {
          return Container(
            child: Center(
              child: Text('No favorites'),
            ),
          );
        }
      },
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
    return Consumer<User>(
      builder: (context, user, child) {
        if (user == null) {
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
                        child: Text('Log out'),
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
