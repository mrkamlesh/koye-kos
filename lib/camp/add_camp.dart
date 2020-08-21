import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong/latlong.dart';
import 'package:transparent_image/transparent_image.dart';

import '../providers.dart';
import '../utils.dart';
import '../models/user.dart';

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
  final _listKey = GlobalKey<AnimatedListState>();
  final descriptionController = TextEditingController();
  final picker = ImagePicker();
  final List<File> _images = [];

  @override
  void initState() {
    super.initState();
    getImage(); // TODO: show dialog to select camera/image picker, then remember the selection ?
  }

  Future getImage() async {
    // Could throw error if no camera available!
    picker
        .getImage(
      source: ImageSource.camera,
    )
        .then((PickedFile pickedFile) {
      if (pickedFile == null) return;
      _images.add(File(pickedFile.path));
      _listKey.currentState.insertItem(_images.length - 1);
    }).catchError((error) {
      Scaffold.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Could not add image: $error'),
        ));
    });
  }

  Future<File> cropImage(File file, int index) {
    ImageCropper.cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg, // default
        compressQuality: 100, // default 90, do compression on image upload
        aspectRatio: CropAspectRatio(ratioX: 4, ratioY: 3),
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Crop image',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        iosUiSettings: IOSUiSettings(
          aspectRatioPickerButtonHidden: true,
          aspectRatioLockEnabled: true,
          title: 'Crop image',
        )).then((File image) {
      if (image == null) return;
      setState(() {
        // TODO: CampImage is not updated with the new image file
        // TODO use two image lists to represent cropped and original file?
        _images[index] = file;
      });
    });
  }

  void deleteImage(int index, {bool animate = false}) {
    final image = _images.removeAt(index);
    _listKey.currentState.removeItem(index, (context, animation) {
      return animate
          ? SizeTransition(
              axis: Axis.horizontal,
              sizeFactor: animation,
              child: CampImage(image, key: Key(image.toString())),
            )
          : SizedBox.shrink();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer((context, watch) {
      final firestore = watch(firestoreService);
      //final AuthProvider auth = watch(authProvider);
      final UserModel user = watch(userProvider);
      return Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              ImageList(_listKey, _images, getImage, deleteImage, cropImage,
                  key: UniqueKey()),
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
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .onPrimary),
                        ),
                        color: Theme
                            .of(context)
                            .primaryColor,
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            bool wasAdded = firestore.addCamp(
                                description: descriptionController.text,
                                location: widget._location,
                                userModel: user, // FIXME
                                images: _images);

                            wasAdded
                                ? Navigator.pop(context, true)
                                : Scaffold.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'You need to have an account to add a camp!',
                                ),
                              ),
                            );
                          }
                        }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    descriptionController.dispose();
  }
}

class ImageList extends StatelessWidget {
  final GlobalKey<AnimatedListState> _listKey;
  final ScrollController _controller = ScrollController();
  final List<File> _images;
  final Function _addCallback;
  final Function(File, int) _onEditCallback;
  final Function(int, {bool animate}) _deleteCallback;
  double imageHeight;
  double imageWidth;

  ImageList(this._listKey, this._images, this._addCallback,
      this._deleteCallback, this._onEditCallback,
      {Key key})
      : super(key: key) {
    // Show images in a 4x3 aspect ratio, reflecting the uploaded image.
    this.imageHeight = 210;
    this.imageWidth = imageHeight * 4 / 3;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: imageHeight,
      child: AnimatedList(
          key: _listKey,
          controller: _controller,
          scrollDirection: Axis.horizontal,
          initialItemCount: 1, // add extra for 'add image' button
          shrinkWrap:
              true, // if true, list wil be centered when only 1 items is added
          itemBuilder: (context, index, animation) {
            bool isButtonIndex = _images.length == index;
            if (!isButtonIndex) {
              final File image = _images[index];
              final Key key = Key(image.toString());
              return SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: animation,
                child: Dismissible(
                  key: key,
                  direction: DismissDirection.up,
                  onDismissed: (direction) {
                    _deleteCallback(index);
                  },
                  child: Container(
                    width: imageWidth,
                    padding: EdgeInsets.only(right: 2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CampImage(image, key: key),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: IconButton(
                              icon: Icon(
                                Icons.crop,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _onEditCallback(image, index);
                              }),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _deleteCallback(index, animate: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Container(
                width: imageWidth,
                padding: EdgeInsets.all(1),
                child: OutlineButton(
                    child: Icon(Icons.add),
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                    onPressed: () => _addCallback(),
                    highlightedBorderColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.12)),
              );
            }
          }),
    );
  }
}

class CampImage extends StatefulWidget {
  final File _image;
  CampImage(this._image, {Key key}) : super(key: key);

  @override
  _CampImageState createState() => _CampImageState(_image);
}

class _CampImageState extends State<CampImage>
    with AutomaticKeepAliveClientMixin {
  FileImage _fileImage;
  bool _loading = true;

  _CampImageState(File file) {
    _fileImage = FileImage(file);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fileImage
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((_, __) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return FadeInImage(
        image: _fileImage,
        placeholder: MemoryImage(kTransparentImage),
        fit: BoxFit.cover,
      );
    }
  }
}
