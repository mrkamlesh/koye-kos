import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:koye_kos/camp/providers/camp_model.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/ui/dialog.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

import '../services/db.dart';
import '../map/map_detail.dart';
import '../models/camp.dart';
import 'add_comment.dart';
import 'providers/comment_model.dart';
import 'comment.dart';
import 'star_rating.dart';

class CampDetailScreen extends StatefulWidget {
  @override
  _CampDetailScreenState createState() => _CampDetailScreenState();
}

class _CampDetailScreenState extends State<CampDetailScreen>
    with SingleTickerProviderStateMixin {
  TabController _controller;

  @override
  void initState() {
    _controller = TabController(length: 2, vsync: this);
    _controller.addListener(_updateState);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final campModel = Provider.of<CampModel>(context);
    Widget _buildFloatingActionButton() {
      return _controller.index == 1
          ? FloatingActionButton(
              child: Icon(Icons.add_comment),
              onPressed: () {
                if (context.read<Auth>().isAuthenticated)
                  Navigator.push<CampComment>(context,
                      MaterialPageRoute(builder: (context) {
                    return ChangeNotifierProvider(
                      create: (context) => CommentModel(
                          originalText: campModel.userComment?.commentText,
                          originalScore: campModel.score),
                      builder: (context, child) => AddCommentScreen(),
                    );
                  })).then(campModel.onCampCommentResult);
                else
                  showDialog(
                    context: context,
                    builder: (_) => LogInDialog(actionText: 'add comment'),
                  );
              },
            )
          : SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        // TODO: look into sizing height of tab bar
        title: Text('Camp'),
        bottom: TabBar(
          controller: _controller,
          tabs: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Info',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Comments'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          CampInfoPage(),
          CommentPage(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    _controller.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }
}

class CampInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final imageUrls =
        context.select((CampModel campModel) => campModel.camp.imageUrls);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChangeNotifierProvider(
              create: (context) => CampPhotoModel(imageUrls: imageUrls),
              child: ImageList()),
          CampInfo(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: UserRatingView(),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: DeleteCamp(),
          ),
        ],
      ),
    );
  }
}

class CampInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Camp camp = Provider.of<CampModel>(context).camp;
    return Padding(
      // Rest of camp description / rating view
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RatingView(
                score: camp.score,
                ratings: camp.ratings,
              ),
              FavoriteWidget(),
            ],
          ),
          Text(camp.description),
          Divider(),
          Text('By: ${camp.creatorName ?? 'Anonymous'}'),
        ],
      ),
    );
  }
}

class UserRatingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final campModel = Provider.of<CampModel>(context);
    final auth = Provider.of<Auth>(context);

    void _toCommentPage(double score) {
      Navigator.push<CampComment>(context,
          MaterialPageRoute(builder: (context) {
            return ChangeNotifierProvider(
              create: (context) => CommentModel(
                  originalText: campModel.userComment?.commentText,
                  originalScore: score),
              builder: (context, child) => AddCommentScreen(),
            );
          })).then(campModel.onCampCommentResult);
    }

    // if authenticated; set score, otherwise ask user to log in and then set score based on action taken
    void _onRatedCallback(double score) {
      auth.isAuthenticated
          ? _toCommentPage(score)
          : showDialog(
              context: context,
              builder: (_) => LogInDialog(actionText: 'rate a camp'),
            ).then((_) => auth.isAuthenticated
                  ? _toCommentPage(score)
                  : campModel.setScore(0)); // user did not log in -> reset score
    }

    return Column(children: [
      Text(
        'Rate',
        style: Theme.of(context).textTheme.headline6,
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: UserRatingWidget(
          score: campModel.score,
          onRatedCallback: _onRatedCallback,
        ),
      ),
    ]);
  }
}

class UserRatingWidget extends StatelessWidget {
  final Function(double score) onRatedCallback;
  final double score;
  UserRatingWidget({this.onRatedCallback, this.score});
  @override
  Widget build(BuildContext context) {
    return StarRating(
      key: UniqueKey(),
      rating: score,
      size: 50,
      color: Colors.amber,
      borderColor: score == 0 ? Colors.amber.shade300 : Colors.amber,
      onRated: onRatedCallback,
    );
  }
}

class RatingView extends StatelessWidget {
  final double score;
  final int ratings;

  RatingView({this.score, this.ratings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: Text('${score.toStringAsFixed(1)}'),
        ),
        StarRating(
          key: UniqueKey(),
          isReadOnly: true,
          rating: score,
          color: Colors.amber,
          borderColor: Colors.amber,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text('($ratings)'),
        ),
      ],
    );
  }
}

class ImageList extends StatefulWidget {
  @override
  _ImageListState createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  @override
  Widget build(BuildContext context) {
    final photoModel = Provider.of<CampPhotoModel>(context);
    final imageUrls = photoModel.imageUrls;
    return Container(
      height: 200, // restrict image height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          bool last = imageUrls.length == index + 1;
          return GestureDetector(
            child: Container(
              width: 340,
              // insert right padding to all but the last list item
              padding: !last ? EdgeInsets.only(right: 2) : null,
              child: CampCachedImage(
                imageUrls[index],
                onLoadCallback: (imageProvider) =>
                    photoModel.onPhotoLoad(imageProvider, index),
              ),
            ),
            onTap: () {
              photoModel.onPhotoTap(index);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<CampPhotoModel>.value(
                      value: photoModel, child: PhotoGallery()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PhotoGallery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final photoModel = Provider.of<CampPhotoModel>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        child: PhotoViewGallery.builder(
          pageController: PageController(
              initialPage: photoModel.startIndex), // TODO: should release?
          builder: (context, index) {
            // TODO: There could be a bug laying here, when trying to view an image that is not loaded yet..
            return PhotoViewGalleryPageOptions(
              imageProvider: photoModel.getImageProvider(index),
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 1.8,
              heroAttributes: PhotoViewHeroAttributes(tag: index),
            );
          },
          itemCount: photoModel.imagesMap.length,
        ),
      ),
    );
  }
}

class DeleteCamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: RaisedButton(
        child: Text(
          'Delete camp',
          style: TextStyle(color: Colors.white),
        ),
        color: Colors.red,
        onPressed: () {
          context.read<CampModel>().deleteCamp();
          Navigator.pop(context);
        },
      ),
    );
  }
}
