import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';
import '../../utils.dart';

enum ImageLoadState {
  Loading,
  Loaded,
}

class AddModel with ChangeNotifier {
  AuthProvider auth;
  FirestoreService firestore;
  Point<double> location;
  final List<CampImage> _campImages = [];

  AddModel(
      {@required this.auth,
      @required this.firestore,
      @required this.location}) {}

  void setAuth(AuthProvider auth) => this.auth = auth;
  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  String get readableLocation =>
      location.toReadableString(precision: 4, separator: ', ');
  List<File> get images =>
      _campImages.map((campImage) => campImage.file).toList();
  File getImage(int index) => _campImages[index].file;
  FileImage getFileImage(int index) => _campImages[index].fileImage;
  CampImage getCampImage(int index) => _campImages[index];
  bool imageIsLoading(int index) => _campImages[index].loadState == ImageLoadState.Loading;

  int addImage(String imagePath) {
    final index = _campImages.length;
    _campImages.add(CampImage(file: File(imagePath)));
    _campImages[index].fileImage
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((_, __) {
      _campImages[index].loadState = ImageLoadState.Loaded;
      notifyListeners();
    }));
    notifyListeners();
    return _campImages.length;
  }

  void updateImage(int index, File image) {
    if (image == null) return;
    _campImages[index]
        .setFile(image)
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((_, __) {
      _campImages[index].loadState = ImageLoadState.Loaded;
      notifyListeners();
    }));
    notifyListeners();
  }

  File removeImage(int index) {
    return _campImages.removeAt(index).file;
  }

  bool addCamp(String description) {
    return true;
  }

  bool isLastElement(int index) => index == _campImages.length;

  @override
  void dispose() {
    super.dispose();
  }
}

class CampImage {
  File file;
  FileImage fileImage;
  ImageLoadState loadState;

  CampImage({this.file}) {
    fileImage = FileImage(file);
    this.loadState = ImageLoadState.Loading;
  }

  FileImage setFile(File file) {
    this.file = file;
    this.loadState = ImageLoadState.Loading;
    return this.fileImage = FileImage(file);
  }
}
