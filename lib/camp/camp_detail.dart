import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:koye_kos/camp/providers/camp_model.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import '../services/db.dart';
import '../map/map_detail.dart';
import '../models/camp.dart';
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
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                return ChangeNotifierProvider(
                  create: (context) =>
                      CommentModel(comment: campModel.userComment),
                  builder: (context, child) => AddCommentScreen(),
                );
              })),
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageList(),
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
    return Column(children: [
      Text(
        'Rate',
        style: Theme.of(context).textTheme.headline6,
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: UserRatingWidget(
          onRatedCallback: campModel.onRated,
          score: campModel.score,
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
      borderColor: Colors.amber,
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
  final Map<int, ImageProvider> images = HashMap();
  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls =
        context.select((CampModel campModel) => campModel.camp.imageUrls);
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
              child: MarkerCachedImage(
                imageUrls[index],
                onLoadCallback: (ImageProvider provider) {
                  images[index] = provider;
                },
              ),
            ),
            onTap: () {
              // TODO: make gallery out of images
              if (!images.containsKey(index)) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Gallery(provider: images[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Gallery extends StatelessWidget {
  final ImageProvider provider;
  const Gallery({
    this.provider,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        child: PhotoView(
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 1.8,
          imageProvider: provider,
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
