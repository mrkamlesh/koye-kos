import * as admin from "firebase-admin";

const functions = require('firebase-functions');

import {Change, EventContext} from "firebase-functions";
import { QueryDocumentSnapshot } from "firebase-functions/lib/providers/firestore";
import DocumentSnapshot = admin.firestore.DocumentSnapshot;

admin.initializeApp();

const db = admin.firestore();

exports.onCommentReportCreate = functions.firestore
    .document('camps/{campId}/comments/{commentId}/reports/{reportId}')
    .onCreate((snapshot: QueryDocumentSnapshot, context:EventContext) => {
        const campId: String = context.params.campId;
        const commentId: String = context.params.commentId;
        const commentRef = db.doc(`camps/${campId}/comments/${commentId}`);
        return commentRef.get().then((commentDoc: DocumentSnapshot) => {
            if (!commentDoc.exists) return;
            const increment = admin.firestore.FieldValue.increment(1);
            return commentRef.update({'reports': increment});
        });

    });

exports.onCommentReportDelete = functions.firestore
    .document('camps/{campId}/comments/{commentId}/reports/{reportId}')
    .onDelete((snapshot: QueryDocumentSnapshot, context:EventContext) => {
        const campId: String = context.params.campId;
        const commentId: String = context.params.commentId;
        const commentRef = db.doc(`camps/${campId}/comments/${commentId}`);
        return commentRef.get().then((commentDoc: DocumentSnapshot) => {
            if (!commentDoc.exists) return;
            const increment = admin.firestore.FieldValue.increment(-1);
            return commentRef.update({'reports': increment});
        });
    });

exports.onReaction = functions.firestore
    .document('camps/{campId}/comments/{commentId}/reactions/{reactionId}')
    .onWrite((change: Change<DocumentSnapshot>, context:EventContext) => {
        if (change.before === change.after) return;  // no change
        const campId: String = context.params.campId;
        const commentId: String = context.params.commentId;
        const reactionId: String = context.params.reactionId;
        const commentRef = db.doc(`camps/${campId}/comments/${commentId}`);
        const reactionRef = db.doc(`camps/${campId}/comments/${commentId}/reactions/${reactionId}`);
        return commentRef.get().then((commentDoc: DocumentSnapshot) => {
            if (!commentDoc.exists) return;
            reactionRef.get().then((reactionDoc: DocumentSnapshot) => {
                // deleted or changed -> remove old reaction
                if (!reactionDoc.exists || change.before.exists) {
                    const likedBefore = <boolean>change.before.get('liked');
                    const revertIncrement = admin.firestore.FieldValue.increment(-1);
                    likedBefore
                        ? commentRef.update({likes: revertIncrement})
                        : commentRef.update({dislikes: revertIncrement});
                    if (!reactionDoc.exists) return;  // reaction deleted -> return
                }
                // created/changed -> add reaction
                const liked = <boolean>change.after.get('liked');
                const increment = admin.firestore.FieldValue.increment(1);
                return liked
                    ? commentRef.update({likes: increment})
                    : commentRef.update({dislikes: increment})
            });
        });
    });