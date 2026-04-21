const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const crypto = require("node:crypto");

admin.initializeApp();
const db = admin.firestore();
const IDEMPOTENCY_COLLECTION = "push_idempotency";
const PROCESSING_TTL_MS = 10 * 60 * 1000;

function cleanString(value, fallback = "") {
  if (typeof value !== "string") return fallback;
  return value.trim();
}

function getAddedItems(before = [], after = []) {
  const beforeSet = new Set(before);
  return after.filter((item) => !beforeSet.has(item));
}

async function getUserDoc(userId) {
  const snap = await db.collection("users").doc(userId).get();
  if (!snap.exists) return null;
  return snap.data() || null;
}

function hashKey(raw) {
  return crypto.createHash("sha256").update(raw).digest("hex");
}

function buildFallbackIdempotencyKey(parts) {
  return hashKey(parts.join("|"));
}

async function acquireIdempotencyLock({ scope, key }) {
  const normalizedKey = cleanString(key);
  if (!normalizedKey) return { acquired: true, docId: null };

  const docId = `${scope}_${hashKey(normalizedKey)}`;
  const ref = db.collection(IDEMPOTENCY_COLLECTION).doc(docId);
  const now = Date.now();

  const acquired = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      tx.set(ref, {
        scope,
        keyHash: hashKey(normalizedKey),
        status: "processing",
        updatedAtMs: now,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return true;
    }

    const data = snap.data() || {};
    const status = cleanString(data.status, "completed");
    const updatedAtMs = Number(data.updatedAtMs || 0);
    const isFreshProcessing =
      status === "processing" && now - updatedAtMs < PROCESSING_TTL_MS;

    if (status === "completed" || isFreshProcessing) {
      return false;
    }

    tx.set(
      ref,
      {
        status: "processing",
        updatedAtMs: now,
        retriedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return true;
  });

  return { acquired, docId };
}

async function markIdempotencyCompleted(docId) {
  if (!docId) return;
  await db.collection(IDEMPOTENCY_COLLECTION).doc(docId).set(
    {
      status: "completed",
      updatedAtMs: Date.now(),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

async function markIdempotencyFailed(docId, reason) {
  if (!docId) return;
  await db.collection(IDEMPOTENCY_COLLECTION).doc(docId).set(
    {
      status: "failed",
      updatedAtMs: Date.now(),
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
      failureReason: cleanString(reason).slice(0, 250),
    },
    { merge: true }
  );
}

async function sendToUserTokens({
  userId,
  title,
  body,
  data,
  idempotencyScope,
  idempotencyKey,
}) {
  const lock = await acquireIdempotencyLock({
    scope: idempotencyScope,
    key: idempotencyKey,
  });
  if (!lock.acquired) {
    logger.info("Skipping duplicate push send", { userId, idempotencyScope });
    return { skipped: true, reason: "duplicate" };
  }

  try {
  const user = await getUserDoc(userId);
  if (!user) {
    logger.info("No user doc found for push", { userId });
    await markIdempotencyCompleted(lock.docId);
    return { successCount: 0, failureCount: 0 };
  }

  const tokens = Array.isArray(user.pushTokens)
    ? user.pushTokens.filter((t) => typeof t === "string" && t.length > 0)
    : [];

  if (tokens.length === 0) {
    logger.info("No push tokens registered", { userId });
    await markIdempotencyCompleted(lock.docId);
    return { successCount: 0, failureCount: 0 };
  }

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: {
      priority: "high",
      notification: {
        channelId: "proactive_channel",
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
      },
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  });

  const invalidTokens = [];
  response.responses.forEach((r, idx) => {
    if (!r.success) {
      const code = r.error?.code || "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        invalidTokens.push(tokens[idx]);
      }
    }
  });

  if (invalidTokens.length > 0) {
    await db.collection("users").doc(userId).set(
      {
        pushTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      },
      { merge: true }
    );
  }

  logger.info("Push send result", {
    userId,
    successCount: response.successCount,
    failureCount: response.failureCount,
  });
  await markIdempotencyCompleted(lock.docId);

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
  };
  } catch (error) {
    await markIdempotencyFailed(lock.docId, error?.message || "unknown");
    throw error;
  }
}

exports.sendMessagePush = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const senderId = request.auth.uid;
  const recipientUserId = cleanString(request.data?.recipientUserId);
  const senderName = cleanString(request.data?.senderName, "Someone");
  const messagePreview = cleanString(
    request.data?.messagePreview,
    "Sent you a message"
  );
  const chatId = cleanString(request.data?.chatId);
  const idempotencyKey =
    cleanString(request.data?.idempotencyKey) ||
    buildFallbackIdempotencyKey([
      senderId,
      recipientUserId,
      chatId,
      messagePreview,
      "message",
    ]);

  if (!recipientUserId || !chatId) {
    throw new HttpsError(
      "invalid-argument",
      "recipientUserId and chatId are required."
    );
  }

  if (recipientUserId === senderId) {
    return { skipped: true, reason: "self" };
  }

  const payload = {
    type: "message",
    senderId,
    chatId,
  };

  await sendToUserTokens({
    userId: recipientUserId,
    title: `${senderName} sent a message`,
    body: messagePreview,
    data: payload,
    idempotencyScope: "message",
    idempotencyKey,
  });

  return { ok: true };
});

exports.sendMatchPush = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const senderId = request.auth.uid;
  const recipientUserId = cleanString(request.data?.recipientUserId);
  const matcherName = cleanString(request.data?.matcherName, "Someone");
  const idempotencyKey =
    cleanString(request.data?.idempotencyKey) ||
    buildFallbackIdempotencyKey([senderId, recipientUserId, "match"]);

  if (!recipientUserId) {
    throw new HttpsError("invalid-argument", "recipientUserId is required.");
  }

  if (recipientUserId === senderId) {
    return { skipped: true, reason: "self" };
  }

  await sendToUserTokens({
    userId: recipientUserId,
    title: "New Match!",
    body: `You matched with ${matcherName}. Start chatting now.`,
    data: {
      type: "match",
      matcherUserId: senderId,
    },
    idempotencyScope: "match",
    idempotencyKey,
  });

  return { ok: true };
});

exports.notifyMutualMatch = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const userId = event.params.userId;
    const before = event.data?.before?.data() || {};
    const after = event.data?.after?.data() || {};

    const beforeFavorites = Array.isArray(before.favoriteUserIds)
      ? before.favoriteUserIds
      : [];
    const afterFavorites = Array.isArray(after.favoriteUserIds)
      ? after.favoriteUserIds
      : [];

    const newlyLikedUserIds = getAddedItems(beforeFavorites, afterFavorites);
    if (newlyLikedUserIds.length === 0) return;

    const likerName = cleanString(after.firstName, "Someone");

    for (const likedUserId of newlyLikedUserIds) {
      if (!likedUserId || likedUserId.startsWith("api_") || likedUserId.startsWith("local_")) {
        continue;
      }

      const likedUser = await getUserDoc(likedUserId);
      if (!likedUser) continue;

      const likedUserFavorites = Array.isArray(likedUser.favoriteUserIds)
        ? likedUser.favoriteUserIds
        : [];

      const isMutual = likedUserFavorites.includes(userId);
      if (!isMutual) continue;
      const matchKey = buildFallbackIdempotencyKey(
        [userId, likedUserId].sort().concat("mutual_match_trigger")
      );

      await sendToUserTokens({
        userId: likedUserId,
        title: "It\'s a Match!",
        body: `You and ${likerName} liked each other.`,
        data: {
          type: "match",
          matcherUserId: userId,
        },
        idempotencyScope: "match-trigger",
        idempotencyKey: matchKey,
      });
    }
  }
);
