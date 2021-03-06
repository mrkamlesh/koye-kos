import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:koye_kos/models/comment.dart';
import 'package:koye_kos/services/auth.dart';
import 'package:koye_kos/ui/dialog.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../map/map_detail.dart';
import '../models/camp.dart';
import 'add_comment.dart';
import 'providers/camp_model.dart';
import 'providers/comment_model.dart';

class CommentPage extends StatelessWidget {
  CommentPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final campModel = Provider.of<CampModel>(context);
    return StreamBuilder<List<CampComment>>(
      stream: campModel.comments,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data.isNotEmpty) {
          final List<CampComment> comments = snapshot.data;
          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return CommentWidget(comment: comments[index]);
                }),
          );
        }
        return Container(
          child: Center(
            child: Text('No comments for this camp. Be the first one!'),
          ),
        );
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
    return Container(  // FIXME: does not constrain card
      width: 600,
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer, // for rounded corners
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              Container(
                width: 600,
                child: Row(
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
                    else
                      PopupMenuButton<bool>(
                        onSelected: (reported) =>
                            context.read<Auth>().isAuthenticated
                                ? campModel.onReportPressed(comment.id,
                                    reported: reported)
                                : showDialog(
                                    context: context,
                                    builder: (context) {
                                      return LogInDialog(
                                        actionText: 'report a comment',
                                      );
                                    },
                                  ),
                        itemBuilder: (context) {
                          return [
                            if (campModel.commentReported(comment.id))
                              PopupMenuItem(
                                child: Text('Remove report'),
                                value: false,
                              )
                            else
                              PopupMenuItem(
                                child: Text('Report comment'),
                                value: true,
                              )
                          ];
                        },
                      )
                  ],
                ),
              ),
              Container(
                width: 600,
                child: Row(
                  children: [
                    if (comment.score != 0)
                      Expanded(
                        child: RatingViewSmall(
                          score: comment.score.toDouble(),
                          showDetails: false,
                        ),
                      ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(child: Text('${DateFormat('dd/MM/yyyy').format(comment.date)}')),
                  ],
                ),
              ),
              Container(
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('${comment.commentText}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
