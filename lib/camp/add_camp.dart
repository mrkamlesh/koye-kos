import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import 'providers/add_camp_model.dart';

class AddCampScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add camp (${context.select((AddModel addModel) => addModel.readableLocation)})',
        ),
      ),
      body: CampForm(),
    );
  }
}

class CampForm extends StatefulWidget {
  @override
  _CampFormState createState() => _CampFormState();
}

class _CampFormState extends State<CampForm> {
  final _formKey = GlobalKey<FormState>();
  final _listKey = GlobalKey<AnimatedListState>();
  final descriptionController = TextEditingController();
  //final picker = Multi();

  @override
  void initState() {
    super.initState();
    //getImage(ImageSource.gallery); // TODO: show dialog to select camera/image picker, then remember the selection ?
  }

  Future getImage() async {
    MultiImagePicker.pickImages(maxImages: 10).then((List<Asset> result) async {
      if (result == null) return;
      List<ByteData> bds = await Future.wait(result.map((e) => e.getByteData()));
      bds.forEach((element) {File.fromRawPath(element.buffer.asUint8List());});
      // TODO: refactor to work with bytedata instead of current pickedFile impl...
      final int newIndex = context.read<AddModel>().addImage(pickedFile.path);
      _listKey.currentState.insertItem(newIndex - 1);
    }).catchError((error) {
      Scaffold.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Could not add image: $error'),
        ));
    });
}

  Future<File> cropImage(int index) {
    ImageCropper.cropImage(
      sourcePath: context.read<AddModel>().getSourceImage(index).path,
      compressFormat: ImageCompressFormat.jpg,
      // default
      compressQuality: 100,
      // default 90, do compression on image upload
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
      ),
    ).then((File image) {
      context.read<AddModel>().updateImage(index, image);
    });
  }

  void deleteImage(int index, {bool animate = false}) {
    final CampImage deletedImage = context.read<AddModel>().removeImage(index);
    _listKey.currentState.removeItem(index, (context, animation) {
      return animate
          ? SizeTransition(
              axis: Axis.horizontal,
              sizeFactor: animation,
              child: CampImageWidget(
                campImage: deletedImage,
              ),
            )
          : SizedBox.shrink();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addModel = Provider.of<AddModel>(context);
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          children: [
            ImageList(
              listKey: _listKey,
              addCallback: getImage,
              deleteCallback: deleteImage,
              onEditCallback: cropImage,
              key: UniqueKey(),
            ),
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
                          bool wasAdded = addModel.addCamp(
                            descriptionController.text,
                          );
                          wasAdded
                              ? Navigator.pop(context, true)
                              : Scaffold.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error uploading camp!',
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
  }

  @override
  void dispose() {
    super.dispose();
    descriptionController.dispose();
  }
}

class ImageList extends StatelessWidget {
  final GlobalKey<AnimatedListState> listKey;
  final ScrollController _controller = ScrollController();
  final Function addCallback;
  final Function(int) onEditCallback;
  final Function(int, {bool animate}) deleteCallback;
  double imageHeight;
  double imageWidth;

  ImageList(
      {@required this.listKey,
      @required this.addCallback,
      @required this.deleteCallback,
      @required this.onEditCallback,
      Key key})
      : super(key: key) {
    // Show images in a 4x3 aspect ratio, reflecting the uploaded image.
    this.imageHeight = 210;
    this.imageWidth = imageHeight * 4 / 3;
  }

  @override
  Widget build(BuildContext context) {
    final addModel = Provider.of<AddModel>(context);
    return Container(
      height: imageHeight,
      child: AnimatedList(
          key: listKey,
          controller: _controller,
          scrollDirection: Axis.horizontal,
          initialItemCount: 1, // add extra for 'add image' button
          shrinkWrap:
              true, // if true, list wil be centered when only 1 items is added
          itemBuilder: (context, index, animation) {
            if (!addModel.isLastElement(index)) {
              final Key key = Key(index.toString());
              return SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: animation,
                child: Dismissible(
                  key: key,
                  direction: DismissDirection.up,
                  onDismissed: (direction) {
                    deleteCallback(index);
                  },
                  child: Container(
                    width: imageWidth,
                    padding: EdgeInsets.only(right: 2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CampImageWidget(
                          campImage: addModel.getCampImage(index),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: IconButton(
                              icon: Icon(
                                Icons.crop,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                onEditCallback(index);
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
                                deleteCallback(index, animate: true),
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
                decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.blue),
                    borderRadius: BorderRadius.all(Radius.circular(1))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: FlatButton(
                        child: Icon(Icons.add_a_photo),
                        onPressed: () => addCallback(),
                      ),
                    ),
                    Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: VerticalDivider(width: 2)),
                    Expanded(
                      child: FlatButton(
                        child: Icon(Icons.add_photo_alternate),
                        onPressed: () => addCallback(),
                      ),
                    )
                  ],
                ),
              );
            }
          }),
    );
  }
}

class CampImageWidget extends StatefulWidget {
  final CampImage campImage;
  CampImageWidget({this.campImage, Key key}) : super(key: key);

  @override
  _CampImageWidgetState createState() => _CampImageWidgetState();
}

class _CampImageWidgetState extends State<CampImageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.campImage.isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return FadeInImage(
        image: widget.campImage.fileImage,
        placeholder: MemoryImage(kTransparentImage),
        fit: BoxFit.cover,
      );
    }
  }
}
