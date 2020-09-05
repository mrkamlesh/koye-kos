import * as admin from "firebase-admin";

const functions = require('firebase-functions');

import {Change, EventContext} from "firebase-functions";
import { QueryDocumentSnapshot } from "firebase-functions/lib/providers/firestore";
import DocumentSnapshot = admin.firestore.DocumentSnapshot;
import FieldValue = admin.firestore.FieldValue;

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
        const commentRef = db.doc(`camps/${campId}/comments/${commentId}`);

        return commentRef.get().then((commentDoc: DocumentSnapshot) => {
            if (!commentDoc.exists) return;
            // deleted or changed (before exists but new value) -> remove old reaction
            if (!change.after.exists || change.before.exists) {
                const likedBefore = <boolean>change.before.get('liked');
                const revertIncrement = FieldValue.increment(-1);
                likedBefore
                    ? commentRef.update({likes: revertIncrement})
                    : commentRef.update({dislikes: revertIncrement});
                if (!change.after.exists) return;  // reaction deleted -> return
            }
            // created/changed -> add reaction
            const liked = <boolean>change.after.get('liked');
            const increment = FieldValue.increment(1);
            return liked
                ? commentRef.update({likes: increment})
                : commentRef.update({dislikes: increment})
        });
    });


exports.onUpdateRating = functions.firestore
    .document('camps/{campId}/ratings/{ratingId}')
    .onWrite((change: Change<DocumentSnapshot>, context:EventContext) => {
        if (change.before === change.after) return;  // no change
        const campId: String = context.params.campId;
        const campRef = db.doc(`camps/${campId}`);
        return db.runTransaction(async (transaction) => {

            const updateRatings = (score: number, ratingsChange: FieldValue) =>
                transaction.update(campRef, {
                    ratings: ratingsChange,
                    score: score,
                });

            const campDoc = await transaction.get(campRef);
            if (!campDoc.exists) return;
            const currentRatings = <number>campDoc.get('ratings');
            const currentScore = <number>campDoc.get('score');
            const currentTotal =  currentScore * currentRatings;

            // User deleted rating -> revert score
            if (!change.after.exists) {
                // check if no score, circumvent 0-divide
                if (currentRatings === 1) return updateRatings(0, FieldValue.increment(-1));
                const userBeforeScore = <number>change.before.get('score');
                const newScore = (currentTotal - userBeforeScore) / (currentRatings - 1);
                return updateRatings(newScore, FieldValue.increment(1));
            }
            // new score
            else if (!change.before.exists) {
                const userAfterScore = <number>change.after.get('score');
                const newScore = (currentTotal + userAfterScore) / (currentRatings + 1);
                return updateRatings(newScore, FieldValue.increment(1));
            }
            // updated score
            else {
                const userBeforeScore = <number>change.before.get('score');
                const userAfterScore = <number>change.after.get('score');
                const newScore = (currentTotal - userBeforeScore + userAfterScore) / currentRatings;
                return updateRatings(newScore, FieldValue.increment(0));
            }
        })
    });

