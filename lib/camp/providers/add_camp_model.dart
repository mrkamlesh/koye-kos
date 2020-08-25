import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';
import '../../utils.dart';

class AddModel with ChangeNotifier {
  AuthProvider auth;
  FirestoreService firestore;
  Point<double> location;
  final List<File> _files = [];
  final List<FileImage> _fileImages = [];
  final _picker = ImagePicker();

  AddModel(
      {@required this.auth,
      @required this.firestore,
      @required this.location}) {}

  void setAuth(AuthProvider auth) => this.auth = auth;
  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  String get readableLocation =>
      location.toReadableString(precision: 4, separator: ', ');
  List<File> get images => _files;
  File getImage(int index) => _files[index];
  FileImage getFileImage(int index) => _fileImages[index];

  void addImage(String imagePath) {
    final File file = File(imagePath);
    _files.add(file);
    _fileImages.add(FileImage(file));
    notifyListeners();
  }

  Future<int> getNewImage() async {
    // Could throw error if no camera available!
    return _picker
        .getImage(source: ImageSource.camera)
        .then((PickedFile pickedFile) {
      if (pickedFile == null) return -1;
      addImage(pickedFile.path);
      return _files.length;
    }).catchError((error) {
      print('Error adding image! $error');
      throw error;
    });
  }

  void updateImage(int index, File image) {
    if (image == null) return;
    _files[index] = image;
    notifyListeners();
  }

  File removeImage(int index) {
    return _files.removeAt(index);
  }

  bool addCamp(String description) {
    return true;
  }

  bool isLastElement(int index) => index == _files.length;

  @override
  void dispose() {
    super.dispose();
  }
}
