import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ImageData {
  String path;
  String pathThumb;
  String imageUrl;
  String thumbnailUrl;

  ImageData({@required this.path, this.imageUrl, this.thumbnailUrl}) {
    pathThumb = path + '_thumb';
  }

  factory ImageData.fromFirestore(DocumentSnapshot document) {
    Map data = document.data();
    return ImageData(
      path: data['path'] as String,
      imageUrl: data['image_url'] as String,
      thumbnailUrl: data['thumbnail_url'] as String,
    );
  }
}
