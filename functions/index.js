const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.deleteAccount = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }
  const {firebaseUid, postSystemMessages} = req.body;
  if (!firebaseUid) {
    return res.status(400).json({message: "Missing firebaseUid"});
  }

  try {
    // Delete user from Auth
    await admin.auth().deleteUser(firebaseUid);

    // Delete user data from Firestore (customize as needed)
    await admin.firestore().collection("users").doc(firebaseUid).delete();

    // Optionally post system messages, etc.
    if (postSystemMessages) {
      // ... your logic here ...
    }

    return res.status(200).json({message: "Account deleted"});
  } catch (error) {
    return res.status(500).json({message: error.message});
  }
});
