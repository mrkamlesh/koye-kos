import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:latlong/latlong.dart';

import 'db.dart';
import 'models.dart';

class AddCampScreen extends StatelessWidget {
  final LatLng location;

  AddCampScreen(this.location);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add camp'),
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
  File _image;

  Future getImage() async {
    // Could throw error if no camera available!
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    setState(() {
      _image = File(pickedFile.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<FirebaseUser>(context);

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  'Location: ${widget._location.latitude.toStringAsFixed(4)}, ${widget._location.longitude.toStringAsFixed(4)}',
                ),
              ),
            ),
            SizedBox(height: 8),
            _buildImageView(),
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
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  print('camp added');
                  Camp newCamp = Camp(
                    imageUrls: ['spot_1_small.jpg', 'spot_1_small.jpg'],
                    description: descriptionController.text,
                    location: widget._location,
                    creatorName: user.displayName,
                    creatorId: user.uid,
                  );
                  //firestoreService.addCamp(newCamp);
                  Navigator.pop(context, true);
                }
              },
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

  Widget _buildImageView() {
    if (_image == null) {
      return OutlineButton.icon(
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
        highlightedBorderColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        icon: const Icon(Icons.add, size: 18),
        label: Text('Add picture'),
        onPressed: () => getImage(),
      );
    } else {
      return SizedBox(
        width: 160,
        height: 160,
        child: Image.file(
          // TODO: load image faster / show loading animation
          _image,
          fit: BoxFit.cover,
        ),
      );
    }
  }
}
