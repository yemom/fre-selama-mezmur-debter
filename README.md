# Music App (Flutter + Firebase)

This workspace contains a step-by-step plan and sample code to build a role-based music app with a Super Admin and Clients.

## 1) App architecture (step-by-step)

1. **Auth and roles**
   - Use Firebase Auth for login.
   - Store roles in custom claims (`admin: true`) and mirror role in Firestore (`users/{uid}`) for quick checks.
   - Blocked users are tracked in `users/{uid}.blocked`.

2. **Data storage**
   - Store song metadata and lyrics in Firestore.
   - Store audio files and cover images in Firebase Storage.

3. **Security enforcement**
   - Clients read-only access to music metadata and lyrics.
   - Super Admin can create/update/delete music and manage users.
   - Enforce rules in Firestore/Storage rules and Cloud Functions (server-side checks).

4. **App flow**
   - Client opens app -> sees music list -> search -> play -> lyrics view.
   - Super Admin logs in -> admin screens -> upload metadata -> manage users.

5. **Scalability**
   - Firestore collections are indexed for search (title/artist fields).
   - Storage uses structured paths: `music/{id}/audio.mp3`, `covers/{id}.jpg`.
   - Cloud Functions provide admin-only endpoints for sensitive operations.

## 2) Database schema (Firestore)

Collections:

- `users/{uid}`
  - `email: string`
  - `displayName: string`
  - `role: "admin" | "client"`
  - `blocked: bool`
  - `createdAt: timestamp`

- `music/{musicId}`
  - `title: string`
  - `artist: string`
  - `album: string`
  - `coverUrl: string`
  - `audioUrl: string`
  - `lyrics: string`
  - `lyricsSync: map` (optional, for time-synced lyrics)
  - `likes: number`
  - `createdBy: uid`
  - `createdAt: timestamp`
  - `updatedAt: timestamp`

- `favorites/{uid}/items/{musicId}`
  - `createdAt: timestamp`

Example document (`music/abc123`):

```
{
  "title": "My Song",
  "artist": "Artist Name",
  "album": "Album Name",
  "coverUrl": "https://.../covers/abc123.jpg",
  "audioUrl": "https://.../music/abc123/audio.mp3",
  "lyrics": "Full lyrics here...",
  "likes": 42,
  "createdBy": "uid_of_admin",
  "createdAt": "2026-02-18T10:00:00Z",
  "updatedAt": "2026-02-18T10:00:00Z"
}
```

## 3) API endpoints (Cloud Functions)

Admin-only endpoints (HTTP):

- `POST /admin/music`
  - Create a music document (metadata + URLs).
- `PUT /admin/music/{musicId}`
  - Update music metadata or lyrics.
- `DELETE /admin/music/{musicId}`
  - Delete music metadata (and optionally cleanup Storage).
- `POST /admin/users/{uid}/block`
  - Block or unblock a user.

Client actions (direct Firestore + Storage reads):

- Read `music` collection
- Read `music/{id}`
- Add favorite: `favorites/{uid}/items/{musicId}`

## 4) Flutter screen list + navigation flow

Screens:

1. **Splash / Auth Gate**
2. **Music List** (default for clients)
3. **Search** (inline on list screen)
4. **Music Player** (audio playback + lyrics)
5. **Favorites**
6. **Admin Login** (email + password)
7. **Admin Dashboard**
8. **Upload / Edit Music**
9. **User Management**

Flow (client):
- Splash -> Music List -> Music Player -> Favorites

Flow (admin):
- Admin Login -> Admin Dashboard -> Upload/Edit -> User Management

## 5) Sample Flutter UI code

- Main app: [flutter_sample/lib/main.dart](flutter_sample/lib/main.dart)
- Music list screen: [flutter_sample/lib/screens/music_list_screen.dart](flutter_sample/lib/screens/music_list_screen.dart)
- Music player screen: [flutter_sample/lib/screens/music_player_screen.dart](flutter_sample/lib/screens/music_player_screen.dart)
- Admin login screen: [flutter_sample/lib/screens/admin_login_screen.dart](flutter_sample/lib/screens/admin_login_screen.dart)
- Music model: [flutter_sample/lib/models/music.dart](flutter_sample/lib/models/music.dart)

## 6) Backend API code (Cloud Functions)

- Functions entry point: [functions_sample/functions/src/index.ts](functions_sample/functions/src/index.ts)

## 7) Role-based authentication logic

1. **Assign admin role**
   - Use a one-time script or admin-only callable function to set custom claims.
   - Custom claims example: `{ "admin": true }`.

2. **Check role in app**
   - After login, call `getIdTokenResult()` and read `claims.admin`.
   - If `true`, show admin screens.

3. **Enforce access**
   - Firestore rules allow only admins to write to `music`.
   - Storage rules allow only admins to upload audio/cover files.
   - Cloud Functions verify admin claims for admin-only endpoints.

## Next steps

1. Wire Flutter to Firebase (Auth, Firestore, Storage).
2. Add `just_audio` for playback and `hive` (or `shared_preferences`) for offline lyrics cache.
3. Deploy rules and Cloud Functions.
