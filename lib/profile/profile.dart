import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:koye_kos/services/db.dart';
import 'package:provider/provider.dart';

import 'favorites.dart';
import 'providers/favorite_provider.dart';
import 'providers/profile_model.dart';

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return context.watch<ProfileModel>().loggedIn
        ? AccountScreen()
        : SignUpView();
  }
}

class SignUpView extends StatefulWidget {
  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _scaffolKey = GlobalKey<ScaffoldState>();

  void _loginCallback(bool success) {
    if (success == null || !success)
      _scaffolKey.currentState
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Log in failed.')));
  }

  @override
  Widget build(BuildContext context) {
    final profileModel = Provider.of<ProfileModel>(context);

    return Scaffold(
      key: _scaffolKey,
      appBar: AppBar(
        title: const Text('Sign up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: profileModel.authenticating
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
              LoginButton(
                provider: LoginProvider.Google,
                providerName: 'GOOGLE',
                buttonColor: Colors.red,
                loginCallback: _loginCallback,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum LoginProvider { Google }

class LoginButton extends StatelessWidget {
  final LoginProvider provider;
  final String providerName;
  final Color buttonColor;
  final Function(bool) loginCallback;
  const LoginButton(
      {@required LoginProvider this.provider,
        @required this.providerName,
        @required this.buttonColor,
        @required this.loginCallback});

  @override
  Widget build(BuildContext context) {
    final profileModel = Provider.of<ProfileModel>(context);
    return RaisedButton(
      child: Text(providerName),
      color: buttonColor,
      onPressed: () {
        if (!profileModel.hasNetwork)
          Scaffold.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text('You need an internet connection to log in.')));
        else
          profileModel.login(provider: provider).then(loginCallback);
      },
    );
  }
}

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profileModel = Provider.of<ProfileModel>(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Account'),
          actions: [
            FlatButton(
              onPressed: profileModel.signOut,
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
            ChangeNotifierProxyProvider<FirestoreService, FavoriteModel>(
                create: (context) =>
                    FavoriteModel(firestore: context.read<FirestoreService>()),
                update: (_, firestore, favoriteModel) =>
                favoriteModel..setFirestore(firestore),
                child: FavoritedView()),
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
    final profileModel = Provider.of<ProfileModel>(context);
    final user = profileModel.user;
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
              child: CachedNetworkImage(
                imageUrl: user.photoUrl,
                placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    child: Center(child: CircularProgressIndicator())),
                imageBuilder: (context, imageProvider) => Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            Text(
              '${user.name}',
              style: Theme.of(context).textTheme.headline6,
            ),
            Text('${user.email}', style: Theme.of(context).textTheme.headline6),
            Divider(height: 40),
          ],
        ),
      ),
    );
  }
}
