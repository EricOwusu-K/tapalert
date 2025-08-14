const { setGlobalOptions } = require("firebase-functions");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

setGlobalOptions({ maxInstances: 10 });
admin.initializeApp();

// Optional: A single test token for emulator mode
// Replace with your own device's FCM token
const TEST_DEVICE_TOKEN = "<YOUR_TEST_DEVICE_FCM_TOKEN>";

exports.sendEmergencyAlertNotification = functions.firestore
  .document("alerts/{alertId}")
  .onCreate(async (snap, context) => {
    const alertData = snap.data();

    try {
      // 1️⃣ Get user info from 'users' collection
      const userRef = admin.firestore().collection("users").doc(alertData.uid);
      const userSnap = await userRef.get();

      if (!userSnap.exists) {
        console.log("User not found for UID:", alertData.uid);
        return;
      }

      const { firstName, surname } = userSnap.data();
      const fullName = `${firstName} ${surname}`;

      // 2️⃣ Get emergency contacts for this user
      const contactsSnap = await admin
        .firestore()
        .collection("contacts")
        .where("ownerId", "==", alertData.uid)
        .get();

      if (contactsSnap.empty) {
        console.log("No emergency contacts found for UID:", alertData.uid);

        // 🔹 In emulator mode, still send to test token
        if (process.env.FUNCTIONS_EMULATOR === "true" && TEST_DEVICE_TOKEN) {
          console.log("Sending to test token (no contacts in emulator)...");
          await sendPush(TEST_DEVICE_TOKEN, fullName, alertData);
        }
        return;
      }

      // 3️⃣ Send notifications to each contact
      for (const contactDoc of contactsSnap.docs) {
        const contactData = contactDoc.data();

        // Find contact's user account by phone
        const userQuery = await admin
          .firestore()
          .collection("users")
          .where("phone", "==", contactData.phone)
          .get();

        if (!userQuery.empty) {
          const contactUserRef = userQuery.docs[0].ref;
          const contactUser = userQuery.docs[0].data();
          const token = contactUser.token;

          if (token) {
            try {
              await sendPush(token, fullName, alertData);
              console.log(`Notification sent to ${contactData.name}`);
            } catch (error) {
              if (
                error.code === "messaging/invalid-argument" ||
                error.code === "messaging/registration-token-not-registered"
              ) {
                console.log(`Removing invalid token for ${contactData.name}`);
                await contactUserRef.update({
                  token: admin.firestore.FieldValue.delete(),
                });
              } else {
                console.error(
                  `Error sending notification to ${contactData.name}:`,
                  error
                );
              }
            }
          } else {
            console.log(`No token for contact: ${contactData.name}`);
          }
        } else {
          console.log(`Contact ${contactData.name} is not a registered user`);
        }
      }
    } catch (error) {
      console.error("Error sending emergency alert notification:", error);
    }
  });

// 🔹 Helper to send push messages
async function sendPush(token, fullName, alertData) {
  const heading = `EMERGENCY ALERT FROM: ${fullName}`;
  const mapsUrl = alertData.map || "No location provided";

  let bodyMessage;
  if (alertData.name) {
    // Gesture alert
    bodyMessage =
      `Name: ${alertData.name}\n` +
      `Category: ${alertData.category}\n` +
      `Time: ${alertData.time}\n` +
      `Map: ${mapsUrl}`;
  } else {
    // Button alert
    bodyMessage =
      `Category: ${alertData.category}\n` +
      `Time: ${alertData.time}\n` +
      `Map: ${mapsUrl}`;
  }

  return admin.messaging().send({
    token,
    notification: {
      title: heading,
      body: bodyMessage,
    },
  });
}
