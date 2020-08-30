import 'package:flutter/material.dart';

class LogInDialog extends StatelessWidget {
  final String actionText;

  LogInDialog({@required this.actionText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log in'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
                'You need to be logged in to $actionText.'),
            Text('Log in or register a user now.'),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Continue without user'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text('Log in / register'),
          onPressed: () {
            Navigator.of(context).pushNamed('/profile').whenComplete(() {
              // Remove dialog after returning so it is possible to check if user is now authenticated or not
              Navigator.of(context).pop();
            });
          },
        ),
      ],
    );
  }
}
