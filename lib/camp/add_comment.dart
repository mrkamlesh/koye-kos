import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:provider/provider.dart';

import 'camp_detail.dart';
import 'providers/comment_model.dart';


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
    final user = Provider.of<Auth>(context).user;
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