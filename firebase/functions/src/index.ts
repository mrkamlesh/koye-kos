import * as admin from "firebase-admin";

const functions = require('firebase-functions');

import {EventContext} from "firebase-functions";
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