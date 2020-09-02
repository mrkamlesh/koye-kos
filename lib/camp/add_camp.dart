import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import 'providers/add_camp_model.dart';

class AddCampScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final addModel = Provider.of<AddModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add camp (${addModel.readableLocation})',
        ),
        actions: [
          AddCampButton(),
        ],
      ),
      body: Column(
        children: [
          AddImageView(),
          CampForm(),
        ],
      ),
    );
  }
}

class AddCampButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final addModel = Provider.of<AddModel>(context);
    return FlatButton(
      child: Text(
        'POST',
        style: TextStyle(
            color: addModel.canPost
                ? Colors.white
                : Colors.white.withOpacity(0.8)),
      ),
      onPressed: () {
        bool wasAdded = addModel.postPressed();
        wasAdded
            ? Navigator.pop(context, true)
            : Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error uploading camp!',
                  ),
                ),
              );
      },
    );
  }
}

class AddImageView extends StatefulWidget {
  @override
  _AddImageViewState createState() => _AddImageViewState();
}

class _AddImageViewState extends State<AddImageView> {
  final _listKey = GlobalKey<AnimatedListState>();

  Future getImage(ImageSource source) async {
    ImagePicker().getImage(source: source).then((PickedFile pickedFile) {
      if (pickedFile == null) return;
      context.read<AddModel>().addImage(pickedFile.path);
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

  @override
  Widget build(BuildContext context) {
    final addModel = Provider.of<AddModel>(context);

    return Column(
      children: [
        SizedBox(height: 8),
        ImageList(
          listKey: _listKey,
          addCallback: getImage,
          onEditCallback: cropImage,
        ),
        addModel.showNoImageError
            ? Container(
                height: 24,
                child: Center(
                  child: Text(
                    'Please add at least 1 image!',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            : SizedBox(height: 24),  // Empty space so error doesn't 'jump' in
      ],
    );
  }
}


class ImageList extends StatelessWidget {
  final GlobalKey<AnimatedListState> listKey;
  final Function(ImageSource) addCallback;
  final Function(int) onEditCallback;
  static const double imageHeight = 210;
  static const double imageWidth = imageHeight * 4 / 3;

  ImageList(
      {@required this.listKey,
        @required this.addCallback,
        @required this.onEditCallback});

  @override
  Widget build(BuildContext context) {
    final addModel = Provider.of<AddModel>(context);
    return Container(
      height: imageHeight,
      child: ImplicitlyAnimatedReorderableList<CampImage>(
        key: listKey,
        items: addModel.campImages,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        areItemsTheSame: (a, b) => a.sourceFile.path == b.sourceFile.path,
        onReorderFinished: addModel.onReorderFinished,
        itemBuilder: (context, itemAnimation, item, index) {
          return Reorderable(
              key: ValueKey(item),
              builder: (context, dragAnimation, inDrag) {
                return SizeTransition(
                  axis: Axis.horizontal,
                  sizeFactor: itemAnimation,
                  child: Handle(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      width: imageWidth,
                      padding: EdgeInsets.only(right: 2),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CampImageWidget(
                            campImage: item,
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
                            right: 2,
                            top: 2,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => addModel.removeImage(index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
        },
        footer: Container(
          width: imageWidth,
          padding: EdgeInsets.all(1),
          decoration: BoxDecoration(
              border: Border.all(
                  width: 1,
                  color: addModel.showNoImageError
                      ? Colors.red.shade700
                      : Colors.blue),
              borderRadius: BorderRadius.all(Radius.circular(1))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FlatButton(
                  child: Icon(Icons.add_a_photo),
                  onPressed: () => addCallback(ImageSource.camera),
                ),
              ),
              Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: VerticalDivider(width: 2)),
              Expanded(
                child: FlatButton(
                  child: Icon(Icons.add_photo_alternate),
                  onPressed: () => addCallback(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ),
      ),
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

class CampForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final addModel = Provider.of<AddModel>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Form(
        child: TextFormField(
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: 5,
          decoration: InputDecoration(
              hintText: 'Enter a short camp description',
              labelText: 'Description',
              errorStyle: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(),
              )),
          validator: (_) => addModel.descriptionValidator,
          onChanged: (value) => addModel.onDescriptionChanged(value),
          autovalidate: addModel.autoValidate,
        ),
      ),
    );
  }
}

