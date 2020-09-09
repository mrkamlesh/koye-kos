import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart' hide NestedScrollView, NestedScrollViewState;
import 'package:flutter/widgets.dart' hide NestedScrollView, NestedScrollViewState;
import 'package:koye_kos/camp/providers/camp_model.dart';
import 'package:koye_kos/models/comment.dart';
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
import 'ui/feature_chips.dart';

class CampDetailScreen extends StatefulWidget {
  @override
  _CampDetailScreenState createState() => _CampDetailScreenState();
}

class _CampDetailScreenState extends State<CampDetailScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<NestedScrollViewState> _key =
  GlobalKey<NestedScrollViewState>();
  TabController _controller;
  List<String> _tabs = ['Info', 'Comments'];

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

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final double pinnedHeaderHeight =
        //statusBar height
        statusBarHeight + kToolbarHeight;

    return NestedScrollView(
      key: _key,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            //forceElevated: innerBoxIsScrolled,
            floating: false,
            pinned: true,
            expandedHeight: 200,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: ChangeNotifierProxyProvider2<Auth, FirestoreService,
                  CampPhotoModel>(
                create: (context) => CampPhotoModel(
                  auth: context.read<Auth>(),
                  firestore: context.read<FirestoreService>(),
                  campId: context.read<CampModel>().camp.id,
                ),
                update: (_, auth, firestore, photoModel) => photoModel
                  ..setAuth(auth)
                  ..setFirestore(firestore),
                child: ImageList(),
              ),
            ),
          ),
        ];
      },
      pinnedHeaderSliverHeightBuilder: () {
        return pinnedHeaderHeight;
      },
      innerScrollPositionKeyBuilder: () {
        String index = 'Tab';
        index += _controller.index.toString();
        return Key(index);
      },
      body: Column(
        children: [
          TabBar(
            controller: _controller,
            labelColor: Colors.blue,
            indicatorColor: Colors.blue,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 2.0,
            isScrollable: false,
            unselectedLabelColor: Colors.grey,
            tabs: _tabs
                .map((tabName) => Tab(
                      text: tabName,
                    ))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: _tabs.map((String tabName) {
                return NestedScrollViewInnerScrollPositionKeyWidget(
                    Key(tabName),
                    tabName == 'Info'
                        ? CampInfoPage(key: PageStorageKey<String>(tabName))
                        : CommentPage(key: PageStorageKey<String>(tabName)));
              }).toList(),
            ),
          ),
        ],
      ),
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
  CampInfoPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CampInfo(),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: CampFeaturesWidget(camp.features),
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
      if (score == 0) return;
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
  final bool greyOnZero;
  UserRatingWidget({this.onRatedCallback, this.score, this.greyOnZero = false});
  @override
  Widget build(BuildContext context) {
    return StarRating(
      key: UniqueKey(),
      rating: score,
      allowHalfRating: false,
      size: 50,
      color: Colors.amber,
      borderColor:
          score == 0 && greyOnZero ? Colors.grey.shade300 : Colors.amber,
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
  final galleryKey = UniqueKey();
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
              padding: !last ? EdgeInsets.only(right: 0) : null,
              child: CampCachedImage(
                imageUrls[index],
              ),
            ),
            onTap: () {
              photoModel.onPhotoTap(index);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<CampPhotoModel>.value(
                    value: photoModel,
                    child: PhotoGallery(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PhotoGallery extends StatefulWidget {
  @override
  _PhotoGalleryState createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  final galleryKey = UniqueKey();
  PageController pageController;

  @override
  void initState() {
    pageController =
        PageController(initialPage: context.read<CampPhotoModel>().startIndex);
    super.initState();
  }

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
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            PhotoViewGallery.builder(
              key: galleryKey,
              pageController: pageController, // TODO: should release?
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider:
                      CachedNetworkImageProvider(photoModel.getUrl(index)),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 1.8,
                  heroAttributes: PhotoViewHeroAttributes(tag: index),
                );
              },
              itemCount: photoModel.imagesCount,
              loadingBuilder: (context, event) {
                return Container(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
            Container(
              color: Colors.black.withOpacity(.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<bool>(
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: 48, minHeight: 48),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        )),
                    onSelected: (reported) =>
                        context.read<Auth>().isAuthenticated
                            ? photoModel.onReportPressed(pageController.page,
                                reported: reported)
                            : showDialog(
                                context: context,
                                builder: (context) {
                                  return LogInDialog(
                                    actionText: 'report an image',
                                  );
                                },
                              ),
                    itemBuilder: (context) {
                      return [
                        if (photoModel.imageReported(pageController.page))
                          PopupMenuItem(
                            child: Text('Remove report'),
                            value: false,
                          )
                        else
                          PopupMenuItem(
                            child: Text('Report image'),
                            value: true,
                          )
                      ];
                    },
                  ),
                ],
              ),
            )
          ],
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
