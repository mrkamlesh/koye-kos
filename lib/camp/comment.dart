import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:koye_kos/providers.dart';

import '../services/db.dart';
import '../map/map_detail.dart';
import '../models/camp.dart';
import '../models/user.dart';
import 'camp_detail.dart';

class CommentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer((context, watch) {
      final firestore = watch(firestoreService);
      final Camp camp = watch(campProvider);
      final UserModel user = watch(userProvider);

      return StreamBuilder<List<CampComment>>(
        stream: firestore.getComments(camp.id),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.isNotEmpty) {
            final List<CampComment> comments = snapshot.data;
            return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final CampComment comment = comments[index];
                  return Card(
                    clipBehavior:
                    Clip.antiAliasWithSaveLayer, // for rounded corners
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0),
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
                                          padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Text('${comment.userName}'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (comment.userId == user.id) IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () =>
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) {
                                          return ProviderScope(
                                            overrides: [
                                              campProvider.overrideWithValue(camp)
                                            ],
                                            child: AddCommentScreen(
                                              comment: comment,),
                                          );
                                        })),)
                            ],
                          ),
                          Row(
                            children: [
                              if (comment.score != null)
                                RatingViewSmall(
                                  score: comment.score,
                                  showDetails: false,
                                ),
                              Text(
                                  '${DateFormat('dd/MM/yyyy').format(
                                      comment.date)}'),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('${comment.comment}'),
                          ),
                        ],
                      ),
                    ),
                  );
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
    });
  }
}

class AddCommentScreen extends StatefulWidget {
  final CampComment comment;

  AddCommentScreen({this.comment});

  @override
  _AddCommentScreenState createState() => _AddCommentScreenState();
}

class _AddCommentScreenState extends State<AddCommentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer((context, watch) {
      final firestore = watch(firestoreService);
      final Camp camp = watch(campProvider);
      final UserModel user = watch(userProvider);

      if (widget.comment != null)
        _textEditingController.text = widget.comment.comment;

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.comment == null ? 'Add comment' : 'Edit comment'),
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
                    firestore.addCampComment(
                        campId: camp.id,
                        comment: _textEditingController.text,
                        userModel: user);
                    Navigator.pop(context);
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
    });
  }
}
