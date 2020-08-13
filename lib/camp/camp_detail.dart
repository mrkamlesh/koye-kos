import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import '../services/db.dart';
import '../map/map_detail.dart';
import '../models.dart';
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
  void dispose() {
    _controller.dispose();
    _controller.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Camp camp = Provider.of<Camp>(context);

    Widget _buildFloatingActionButton() {
      return _controller.index == 1
          ? FloatingActionButton(
              child: Icon(Icons.add_comment),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                return Provider<Camp>.value(
                  value: camp,
                  child: AddCommentScreen(),
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
          InfoWidget(),
          CommentsWidget(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}

class AddCommentScreen extends StatefulWidget {
  @override
  _AddCommentScreenState createState() => _AddCommentScreenState();
}

class _AddCommentScreenState extends State<AddCommentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _listKey = GlobalKey<AnimatedListState>();
  final _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add comment'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FlatButton(
              child: Text(
                'POST',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => print('todo: add to firebase'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                UserRatingWidget(),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _textEditingController,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 10,
                  maxLength: 500,
                  decoration: InputDecoration(
                      hintText: 'Enter a comment',
                      labelText: 'Comment',
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
                )
              ],
            ), // TODO: should not post to firebase until user presses 'POST'
          ),
        ),
      ),
    );
  }
}

class CommentsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Row(
          children: [
            Icon(Icons.comment),
          ],
        ),
      ),
    );
  }
}

class InfoWidget extends StatelessWidget {
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

class UserRatingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        'Rate',
        style: Theme.of(context).textTheme.headline6,
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: UserRatingWidget(),
      ),
    ]);
  }
}

class UserRatingWidget extends StatefulWidget {
  @override
  _UserRatingWidgetState createState() => _UserRatingWidgetState();
}

class _UserRatingWidgetState extends State<UserRatingWidget> {
  double _score = 0;

  @override
  void initState() {
    final String campId = context.read<Camp>().id;
    final String userId = context.read<User>().id;
    context
        .read<FirestoreService>()
        .getCampRating(userId, campId)
        .then((double score) {
      setState(() {
        _score = score;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String campId = context.select((Camp camp) => camp.id);
    final String userId = context.select((User user) => user.id);
    final firestoreService = Provider.of<FirestoreService>(context);
    return StarRating(
      key: UniqueKey(),
      rating: _score,
      size: 50,
      color: Colors.amber,
      borderColor: Colors.amber,
      onRated: (rating) {
        firestoreService.updateRating(campId, userId, rating);
        setState(() {
          _score = rating;
        });
      },
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

class CampInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Camp camp = Provider.of<Camp>(context);
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

class ImageList extends StatefulWidget {
  @override
  _ImageListState createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  final Map<int, ImageProvider> images = HashMap();
  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls =
        context.select((Camp camp) => camp.imageUrls);
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
    final String campId = context.select((Camp camp) => camp.id);
    final firestoreService = Provider.of<FirestoreService>(context);
    return Center(
      child: RaisedButton(
        child: Text(
          'Delete camp',
          style: TextStyle(color: Colors.white),
        ),
        color: Colors.red,
        onPressed: () {
          firestoreService.deleteCamp(campId);
          Navigator.pop(context);
        },
      ),
    );
  }
}
