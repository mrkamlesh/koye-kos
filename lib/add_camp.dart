import 'dart:ffi';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:latlong/latlong.dart';

import 'db.dart';
import 'models.dart';
import 'utils.dart';

class AddCampScreen extends StatelessWidget {
  final LatLng location;

  AddCampScreen(this.location);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Add camp (${location.toReadableString(precision: 4, separator: ', ')})'),
      ),
      body: CampForm(location),
    );
  }
}

class CampForm extends StatefulWidget {
  final LatLng _location;
  CampForm(this._location);

  @override
  _CampFormState createState() => _CampFormState();
}

class _CampFormState extends State<CampForm> {
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final picker = ImagePicker();
  final List<File> _images = [];

  @override
  void initState() {
    super.initState();
    getImage();
  }

  Future getImage() async {
    // Could throw error if no camera available!
    final pickedFile = await picker.getImage(
        source: ImageSource.camera,
        /* maxHeight: 800,
        maxWidth: 800,*/
        imageQuality: 40);
    setState(() {
      _images.add(File(pickedFile.path));
    });
  }

  void deleteImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          children: [
            ImageList(_images, getImage, deleteImage),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                        hintText: 'Enter a short camp description',
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(),
                        )),
                    validator: (value) {
                      if (value.length < 0) {
                        // PROD: change to meaningful value
                        return 'Please enter short a description!';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  RaisedButton(
                    child: Text(
                      'Add camp',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary),
                    ),
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        firestoreService
                            .addCamp(
                                description: descriptionController.text,
                                location: widget._location,
                                creatorId: user.uid,
                                creatorName: user.displayName,
                                images: _images)
                            .then((bool uploadSuccessful) {
                          if (uploadSuccessful)
                            Navigator.pop(context, true);
                          else
                            Scaffold.of(context)
                              ..removeCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                  content: Text('Error uploading camp.')));
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    descriptionController.dispose();
  }
}

class ImageList extends StatelessWidget {
  final List<File> _images;
  final Function _addCallback;
  final Function(int) _deleteCallback;

  ImageList(this._images, this._addCallback, this._deleteCallback);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      child: ListView.builder(
          // TODO: animate adding new picture?
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: _images.length + 1,
          itemBuilder: (context, index) {
            bool last = _images.length == index;
            return Container(
              width: 200,
              padding: !last ? EdgeInsets.only(right: 2) : null,
              child: _images.length - index > 0
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _images[index],
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            onPressed: () => _deleteCallback(index),
                          ),
                        )
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Container(
                        child: OutlineButton(
                            child: Icon(Icons.add),
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                            onPressed: () => _addCallback(),
                            highlightedBorderColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.12)),
                      ),
                    ),
            );
          }),
    );
  }
}
