import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/db.dart';
import '../map/map_detail.dart';
import '../models/camp.dart';
import '../models/user.dart';
import 'camp_detail.dart';
import 'providers/camp_model.dart';
import 'providers/comment_model.dart';

class CommentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final campModel = Provider.of<CampModel>(context);
    return StreamBuilder<List<CampComment>>(
      stream: campModel.comments,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data.isNotEmpty) {
          final List<CampComment> comments = snapshot.data;
          return ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return CommentWidget(comment: comments[index]);
              });
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                CircularProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text('Loading comments...'),
                ),
              ],
            ),
          );
        } else {
          return Container(
            child: Center(
              child: Text('No comments for this camp. Be the first one!'),
            ),
          );
        }
      },
    );
  }
}

class CommentWidget extends StatelessWidget {
  const CommentWidget({@required this.comment});
  final CampComment comment;

  @override
  Widget build(BuildContext context) {
    final campModel = Provider.of<CampModel>(context);
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer, // for rounded corners
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      height: 40,
                      child: Row(
                        children: [
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: comment.userPhotoUrl,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('${comment.userName}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (campModel.isCreator(comment.userId))
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => Navigator.push<CampComment>(context,
                        MaterialPageRoute(builder: (context) {
                          return ChangeNotifierProvider(
                            create: (context) => CommentModel(
                                originalText: comment.commentText,
                                originalScore: campModel.score),
                            builder: (context, child) => AddCommentScreen(),
                          );
                        })).then(campModel.onCampCommentResult),
                  )
              ],
            ),
            Row(
              children: [
                if (comment.score != null)
                  RatingViewSmall(
                    score: comment.score,
                    showDetails: false,
                  ),
                SizedBox(
                  width: 8,
                ),
                Text('${DateFormat('dd/MM/yyyy').format(comment.date)}'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('${comment.commentText}'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCommentScreen extends StatefulWidget {
  @override
  _AddCommentScreenState createState() => _AddCommentScreenState();
}

class _AddCommentScreenState extends State<AddCommentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      final String commentText = _textEditingController.text;
      Provider.of<CommentModel>(context, listen: false)
          .onTextChange(commentText);
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentModel = Provider.of<CommentModel>(context);
    final user = Provider.of<AuthProvider>(context).user;
    if (!commentModel.isNewComment)
      _textEditingController.text = commentModel.originalText;

    return Scaffold(
      appBar: AppBar(
        title: Text(commentModel.title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FlatButton(
              child: Text(
                'POST',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  final text = _textEditingController.text;
                  Navigator.pop(context, commentModel.getComment());
                }
              },
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
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: user.photoUrl,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('${user.name}'),
                ),
                SizedBox(
                  height: 8,
                ),
                UserRatingWidget(
                  onRatedCallback: commentModel.onRated,
                  score: commentModel.score,
                ),
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
                ),
                if (!commentModel.isNewComment) Center(
                  child: RaisedButton(
                    child: Text(
                      'Delete comment',
                      style: TextStyle(color: Colors.white),
                    ),
                    color: Colors.red,
                    onPressed: () {
                      commentModel.deleteComment();
                      Navigator.pop(context, commentModel.getComment());
                    },
                  ),
                ),
              ],
            ), //
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
