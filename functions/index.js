const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggers when a bill is created or updated.
 * If status is 'assigned', sends individual push notifications to all assigned members.
 */
exports.notifyMembersOnBillAssigned = onDocumentWritten("bills/{billId}", async (event) => {
  const afterData = event.data.after ? event.data.after.data() : null;
  const beforeData = event.data.before ? event.data.before.data() : null;

  if (!afterData) return; // Bill was deleted

  // Only trigger if status is 'assigned' and either newly created or status transitioned
  const isNowAssigned = afterData.status === "assigned";
  const wasAlreadyAssigned = beforeData && beforeData.status === "assigned";

  if (!isNowAssigned || wasAlreadyAssigned) {
    return;
  }

  const billId = event.params.billId;
  const billTitle = afterData.title || "Bill";
  const splits = afterData.splits || {};
  const paidByUid = afterData.paidByUserId;

  // Fetch payer name
  let payerName = "Someone";
  if (paidByUid) {
    const payerDoc = await admin.firestore().collection("users").doc(paidByUid).get();
    if (payerDoc.exists && payerDoc.data().displayName) {
      payerName = payerDoc.data().displayName;
    }
  }

  const sendPromises = [];

  for (const [userId, splitInfo] of Object.entries(splits)) {
    // Don't send notification to the person who paid the bill
    if (userId === paidByUid) continue;

    const amount = Number(splitInfo.totalPayable || 0);
    if (amount <= 0) continue;

    const promise = admin.firestore().collection("users").doc(userId).get().then(async (userDoc) => {
      if (!userDoc.exists) return;

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        console.log(`No FCM token found for user ${userId}`);
        return;
      }

      const message = {
        token: fcmToken,
        notification: {
          title: `🧾 New Bill Share: ${billTitle}`,
          body: `Hey! You owe $${amount.toFixed(2)} to ${payerName}. Tap to view items.`,
        },
        data: {
          billId: billId,
          amount: amount.toFixed(2),
          type: "bill_assigned",
        },
      };

      try {
        await admin.messaging().send(message);
        console.log(`Notification successfully sent to user ${userId}`);
      } catch (err) {
        console.error(`Error sending notification to ${userId}:`, err);
      }
    });

    sendPromises.push(promise);
  }

  await Promise.all(sendPromises);
});
