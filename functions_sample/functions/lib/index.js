"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setUserRole = exports.approveAdminRequest = exports.requestAdminAccess = exports.onUserCreate = exports.api = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const express_1 = __importDefault(require("express"));
admin.initializeApp();
const db = admin.firestore();
const app = (0, express_1.default)();
app.use(express_1.default.json());
async function requireApprovedAdmin(req, res) {
    const authHeader = req.headers.authorization || '';
    const match = authHeader.match(/^Bearer (.*)$/);
    if (!match) {
        res.status(401).json({ error: 'Missing auth token' });
        return null;
    }
    try {
        const token = await admin.auth().verifyIdToken(match[1]);
        if (token.superAdmin === true) {
            return token;
        }
        if (token.admin !== true) {
            res.status(403).json({ error: 'Admin only' });
            return null;
        }
        const userDoc = await db.collection('users').doc(token.uid).get();
        const approved = userDoc.data()?.adminApproved === true;
        if (!approved) {
            res.status(403).json({ error: 'Admin approval required' });
            return null;
        }
        return token;
    }
    catch (err) {
        res.status(401).json({ error: 'Invalid token' });
        return null;
    }
}
async function requireSuperAdmin(req, res) {
    const authHeader = req.headers.authorization || '';
    const match = authHeader.match(/^Bearer (.*)$/);
    if (!match) {
        res.status(401).json({ error: 'Missing auth token' });
        return null;
    }
    try {
        const token = await admin.auth().verifyIdToken(match[1]);
        if (token.superAdmin !== true) {
            res.status(403).json({ error: 'Super admin only' });
            return null;
        }
        return token;
    }
    catch (err) {
        res.status(401).json({ error: 'Invalid token' });
        return null;
    }
}
app.post('/admin/music', async (req, res) => {
    const token = await requireApprovedAdmin(req, res);
    if (!token) {
        return;
    }
    const { title, artist, album, coverUrl, audioUrl, lyrics } = req.body || {};
    if (!title || !artist || !audioUrl) {
        res.status(400).json({ error: 'Missing required fields' });
        return;
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    const doc = await db.collection('music').add({
        title,
        artist,
        album: album || '',
        coverUrl: coverUrl || '',
        audioUrl,
        lyrics: lyrics || '',
        likes: 0,
        createdBy: token.uid,
        createdAt: now,
        updatedAt: now,
    });
    res.status(201).json({ id: doc.id });
});
app.put('/admin/music/:id', async (req, res) => {
    const token = await requireApprovedAdmin(req, res);
    if (!token) {
        return;
    }
    const { id } = req.params;
    const updates = {
        ...req.body,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.collection('music').doc(id).update(updates);
    res.json({ ok: true });
});
app.delete('/admin/music/:id', async (req, res) => {
    const token = await requireApprovedAdmin(req, res);
    if (!token) {
        return;
    }
    const { id } = req.params;
    await db.collection('music').doc(id).delete();
    res.json({ ok: true });
});
app.post('/admin/users/:uid/block', async (req, res) => {
    const token = await requireSuperAdmin(req, res);
    if (!token) {
        return;
    }
    const { uid } = req.params;
    const { blocked } = req.body || {};
    await db.collection('users').doc(uid).set({ blocked: !!blocked }, { merge: true });
    res.json({ ok: true });
});
exports.api = functions.https.onRequest(app);
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
    await db.collection('users').doc(user.uid).set({
        email: user.email || '',
        displayName: user.displayName || '',
        role: 'client',
        adminApproved: false,
        blocked: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});
exports.requestAdminAccess = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Not signed in');
    }
    const uid = context.auth.uid;
    const email = context.auth.token.email || '';
    await db.collection('adminRequests').doc(uid).set({
        uid,
        email,
        status: 'pending',
        requestedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { ok: true };
});
exports.approveAdminRequest = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Not signed in');
    }
    const requester = await admin.auth().getUser(context.auth.uid);
    const isSuperAdmin = requester.customClaims?.superAdmin === true;
    if (!isSuperAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Super admin only');
    }
    const { uid, approve } = data || {};
    if (!uid || typeof approve !== 'boolean') {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid request');
    }
    if (approve) {
        await admin.auth().setCustomUserClaims(uid, { admin: true, superAdmin: false });
        await db.collection('users').doc(uid).set({ role: 'admin', adminApproved: true }, { merge: true });
    }
    await db.collection('adminRequests').doc(uid).set({
        status: approve ? 'approved' : 'rejected',
        decidedBy: context.auth.uid,
        decidedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { ok: true };
});
exports.setUserRole = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Not signed in');
    }
    const requester = await admin.auth().getUser(context.auth.uid);
    const isSuperAdmin = requester.customClaims?.superAdmin === true;
    if (!isSuperAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Super admin only');
    }
    const { uid, role } = data || {};
    if (!uid || (role !== 'super_admin' && role !== 'admin' && role !== 'client')) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid role');
    }
    if (role === 'super_admin') {
        await admin.auth().setCustomUserClaims(uid, { admin: true, superAdmin: true });
        await db.collection('users').doc(uid).set({ role: 'super_admin', adminApproved: true }, { merge: true });
    }
    else if (role === 'admin') {
        await admin.auth().setCustomUserClaims(uid, { admin: true, superAdmin: false });
        await db.collection('users').doc(uid).set({ role: 'admin', adminApproved: true }, { merge: true });
    }
    else {
        await admin.auth().setCustomUserClaims(uid, { admin: false, superAdmin: false });
        await db.collection('users').doc(uid).set({ role: 'client', adminApproved: false }, { merge: true });
    }
    return { ok: true };
});
