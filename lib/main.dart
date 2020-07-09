import 'package:flutter/material.dart';
import 'package:koye_kos/map.dart';


void main() => runApp(Application());

class Application extends StatefulWidget {
  @override
  _ApplicationState createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Køye Kos',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Køye Kos'),
        ),
        body: Center(
          child: Container(
            child: HammockMap(),
          ),
        ),
      ),
    );
  }
}
