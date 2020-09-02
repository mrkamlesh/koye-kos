import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/services/db.dart';
import '../../utils.dart';

enum ImageLoadState {
  Loading,
  Loaded,
}

class AddModel with ChangeNotifier {
  Auth auth;
  FirestoreService firestore;
  Point<double> location;
  final List<CampImage> _campImages = [];
  String _description = '';
  bool _postPressed = false;

  AddModel(
      {@required this.auth,
      @required this.firestore,
      @required this.location}) {}

  void setAuth(Auth auth) => this.auth = auth;
  void setFirestore(FirestoreService firestore) => this.firestore = firestore;

  String get readableLocation =>
      location.toReadableString(precision: 4, separator: ', ');
  bool get canPost => _campImages.isNotEmpty && _description.isNotEmpty;
  bool get showNoImageError => _postPressed && _campImages.isEmpty;
  bool get autoValidate => _postPressed;
  List<File> get images =>
      _campImages.map((campImage) => campImage.file).toList();
  File getSourceImage(int index) => _campImages[index].sourceFile;
  File getImage(int index) => _campImages[index].file;
  List<CampImage> get campImages => _campImages;
  CampImage getCampImage(int index) => _campImages[index];

  int addImage(String imagePath) {
    final index = _campImages.length;
    _campImages.add(CampImage(sourceFile: File(imagePath)));
    _campImages[index]
        .fileImage
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

  void removeImage(int index) {
    _campImages.removeAt(index);
    notifyListeners();
  }

  void onReorderFinished(CampImage item, int from, int to, List<CampImage> newItems) {
    _campImages.clear();
    _campImages.addAll(newItems);
  }

  void postPressed() {
    _postPressed = true;
    notifyListeners();
  }

  void onDescriptionChanged(String value) {
    _description = value.trim();
    notifyListeners();
  }

  String get descriptionValidator {
    print(_description);
    return _description.length > 0
        ? null
        : 'Please enter a short description!';
  }

  bool addCamp() {
    final images = _campImages.map((campImage) => campImage.file).toList();
    return firestore.addCamp(
      description: _description,
      location: location,
      images: images,
    );
  }

  bool isLastElement(int index) => index == _campImages.length;

  @override
  void dispose() {
    super.dispose();
  }
}

class CampImage {
  File sourceFile;
  File file;
  FileImage fileImage;
  ImageLoadState loadState;

  CampImage({this.sourceFile}) {
    file = sourceFile;
    fileImage = FileImage(sourceFile);
    this.loadState = ImageLoadState.Loading;
  }

  FileImage setFile(File file) {
    this.file = file;
    this.loadState = ImageLoadState.Loading;
    return this.fileImage = FileImage(file);
  }

  bool get isLoading => loadState == ImageLoadState.Loading;
}
