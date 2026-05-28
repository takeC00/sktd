const { onUserCreated, onUserDeleted } = require("firebase-functions/v2/identity");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({ region: "asia-northeast1" });

const db = admin.firestore();

/**
 * Auth作成 → Firestore users/{uid} 自動作成
 */
exports.syncUserOnAuthCreate = onUserCreated(async (event) => {
  const user = event.data;
  if (!user) return;

  const uid = user.uid;
  const email = user.email ?? null;
  const name = user.displayName ?? "";

  await db.collection("users").doc(uid).set(
    {
      name,
      email,
      rating: 1500,
      currentCircleId: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
});

/**
 * Auth削除 → Firestore users/{uid} & 関連データ掃除
 * - users/{uid}
 * - circleMembers where userId == uid
 * - circles: memberIds から uid を arrayRemove
 */
exports.syncUserOnAuthDelete = onUserDeleted(async (event) => {
  const user = event.data;
  if (!user) return;

  const uid = user.uid;

  // 1) circleMembers から削除（クエリ）
  const membershipsSnap = await db
    .collection("circleMembers")
    .where("userId", "==", uid)
    .get();

  // 2) circles.memberIds から uid を削除（クエリ）
  const circlesSnap = await db
    .collection("circles")
    .where("memberIds", "array-contains", uid)
    .get();

  // バッチは500件制限があるので分割
  const deleteOps = [];
  membershipsSnap.docs.forEach((doc) => {
    deleteOps.push({ type: "delete", ref: doc.ref });
  });
  circlesSnap.docs.forEach((doc) => {
    deleteOps.push({ type: "update", ref: doc.ref });
  });

  const chunkSize = 450;
  for (let i = 0; i < deleteOps.length; i += chunkSize) {
    const chunk = deleteOps.slice(i, i + chunkSize);
    const batch = db.batch();

    for (const op of chunk) {
      if (op.type === "delete") {
        batch.delete(op.ref);
      } else {
        batch.update(op.ref, {
          memberIds: admin.firestore.FieldValue.arrayRemove(uid),
        });
      }
    }
    await batch.commit();
  }

  // 3) users/{uid} を削除
  await db.collection("users").doc(uid).delete();
});

