import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:koye_kos/auth.dart';
import 'package:koye_kos/main.dart';
import 'package:provider/provider.dart';

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseUser user = Provider.of<FirebaseUser>(context);
    AuthService.instance.currentUser.then((value) => print('Displayname:: ${value?.displayName}'));
    /*print(user);
    print(user?.uid);
    print(user?.isAnonymous);
    print(user?.email);
    print(user?.displayName);
    print(user == null || user.isAnonymous);*/
    return user == null || user.isAnonymous
            ? SignUpView()
            : AccountView();
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
    final FirebaseUser user = Provider.of<FirebaseUser>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0,),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipOval(child: CachedNetworkImage(imageUrl: user.photoUrl,),),
              ),
              Text('${user.displayName}', style: Theme.of(context).textTheme.headline6,),
              Text('${user.email}', style: Theme.of(context).textTheme.headline6),
              SizedBox(height: 50,),
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
      ),
    );
  }
}
