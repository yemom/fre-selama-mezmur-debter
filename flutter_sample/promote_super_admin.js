// promote_super_admin.js
const admin = require("firebase-admin");

const serviceAccount = require(
  "./freselama-sunday-school-firebase-adminsdk-fbsvc-b628cee2a8.json"
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: "freselama-sunday-school",
});

async function resolveSuperAdminUser() {
  const email = process.env.SUPER_ADMIN_EMAIL || "";
  const password = process.env.SUPER_ADMIN_PASSWORD || "";
  const uid = process.env.SUPER_ADMIN_UID || "";
  const name = process.env.SUPER_ADMIN_NAME || "Super Admin";

  if (email) {
    if (!password) {
      throw new Error("Missing SUPER_ADMIN_PASSWORD for email flow");
    }
    try {
      return await admin.auth().getUserByEmail(email);
    } catch (error) {
      if (error && error.code === "auth/user-not-found") {
        return await admin.auth().createUser({
          email,
          password,
          displayName: name,
        });
      }
      throw error;
    }
  }

  if (!uid) {
    throw new Error("Missing SUPER_ADMIN_EMAIL or SUPER_ADMIN_UID");
  }
  return await admin.auth().getUser(uid);
}

async function promoteSuperAdmin() {
  try {
    const user = await resolveSuperAdminUser();
    const uid = user.uid;

    await admin.auth().setCustomUserClaims(uid, {
      role: "super-admin",
      admin: true,
      superAdmin: true,
    });

    await admin.firestore().collection("users").doc(uid).set(
      {
        name: user.displayName || "Super Admin",
        email: user.email || process.env.SUPER_ADMIN_EMAIL || "",
        role: "super-admin",
        adminApproved: true,
        blocked: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log("Super admin ready:", uid);
  } catch (error) {
    console.error("Error:", error.message || error);
  }
}

promoteSuperAdmin();