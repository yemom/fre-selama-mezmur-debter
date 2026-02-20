import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import express from 'express';

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(express.json());

async function requireApprovedAdmin(
    req: express.Request,
    res: express.Response,
): Promise<admin.auth.DecodedIdToken | null> {
    const authHeader = req.headers.authorization || '';
    const match = authHeader.match(/^Bearer (.*)$/);
    if (!match) {
        res.status(401).json({ error: 'Missing auth token' });
        return null;
    }

    try {
        const token = await admin.auth().verifyIdToken(match[1]);
        if (token.superAdmin === true || token.role === 'super-admin') {
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
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
        return null;
    }
}

async function requireSuperAdmin(
    req: express.Request,
    res: express.Response,
): Promise<admin.auth.DecodedIdToken | null> {
    const authHeader = req.headers.authorization || '';
    const match = authHeader.match(/^Bearer (.*)$/);
    if (!match) {
        res.status(401).json({ error: 'Missing auth token' });
        return null;
    }

    try {
        const token = await admin.auth().verifyIdToken(match[1]);
        if (token.superAdmin !== true && token.role !== 'super-admin') {
            res.status(403).json({ error: 'Super admin only' });
            return null;
        }
        return token;
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
        return null;
    }
}

app.post('/admin/music', async (req: express.Request, res: express.Response) => {
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

app.put('/admin/music/:id', async (req: express.Request, res: express.Response) => {
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

app.delete('/admin/music/:id', async (req: express.Request, res: express.Response) => {
    const token = await requireApprovedAdmin(req, res);
    if (!token) {
        return;
    }

    const { id } = req.params;
    await db.collection('music').doc(id).delete();
    res.json({ ok: true });
});

app.post('/admin/users/:uid/block', async (req: express.Request, res: express.Response) => {
    const token = await requireSuperAdmin(req, res);
    if (!token) {
        return;
    }

    const { uid } = req.params;
    const { blocked } = req.body || {};
    await db.collection('users').doc(uid).set({ blocked: !!blocked }, { merge: true });
    res.json({ ok: true });
});

export const api = functions.https.onRequest(app);

export const onUserCreate = functions.auth.user().onCreate(async (user: admin.auth.UserRecord) => {
    await db.collection('users').doc(user.uid).set({
        email: user.email || '',
        displayName: user.displayName || '',
        role: 'client',
        adminApproved: false,
        blocked: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});

export const requestAdminAccess = functions.https.onCall(
    async (_data: unknown, context: functions.https.CallableContext) => {
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

export const approveAdminRequest = functions.https.onCall(
    async (
        data: { uid?: string; approve?: boolean },
        context: functions.https.CallableContext,
    ) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Not signed in');
        }

        const requester = await admin.auth().getUser(context.auth.uid);
        const isSuperAdmin = requester.customClaims?.superAdmin === true ||
            requester.customClaims?.role === 'super-admin';
        if (!isSuperAdmin) {
            throw new functions.https.HttpsError('permission-denied', 'Super admin only');
        }

        const { uid, approve } = data || {};
        if (!uid || typeof approve !== 'boolean') {
            throw new functions.https.HttpsError('invalid-argument', 'Invalid request');
        }

        if (approve) {
            await admin.auth().setCustomUserClaims(uid, { admin: true, superAdmin: false });
            await db.collection('users').doc(uid).set(
                { role: 'admin', adminApproved: true },
                { merge: true },
            );
        }

        await db.collection('adminRequests').doc(uid).set(
            {
                status: approve ? 'approved' : 'rejected',
                decidedBy: context.auth.uid,
                decidedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
        );

        return { ok: true };
    });

export const setUserRole = functions.https.onCall(
    async (
        data: { uid?: string; role?: string },
        context: functions.https.CallableContext,
    ) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Not signed in');
        }

        const requester = await admin.auth().getUser(context.auth.uid);
        const isSuperAdmin = requester.customClaims?.superAdmin === true;
        if (!isSuperAdmin) {
            throw new functions.https.HttpsError('permission-denied', 'Super admin only');
        }

        const { uid, role } = data || {};
        if (!uid || (role !== 'super-admin' && role !== 'admin' && role !== 'client')) {
            throw new functions.https.HttpsError('invalid-argument', 'Invalid role');
        }

        if (role === 'super-admin') {
            await admin.auth().setCustomUserClaims(uid, {
                role: 'super-admin',
                admin: true,
                superAdmin: true,
            });
            await db.collection('users').doc(uid).set(
                { role: 'super-admin', adminApproved: true },
                { merge: true },
            );
        } else if (role === 'admin') {
            await admin.auth().setCustomUserClaims(uid, {
                role: 'admin',
                admin: true,
                superAdmin: false,
            });
            await db.collection('users').doc(uid).set(
                { role: 'admin', adminApproved: true },
                { merge: true },
            );
        } else {
            await admin.auth().setCustomUserClaims(uid, {
                role: 'client',
                admin: false,
                superAdmin: false,
            });
            await db.collection('users').doc(uid).set(
                { role: 'client', adminApproved: false },
                { merge: true },
            );
        }

        return { ok: true };
    });
