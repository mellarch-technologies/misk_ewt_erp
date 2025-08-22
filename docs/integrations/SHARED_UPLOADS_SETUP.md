# Shared Hosting Uploads Setup (ERP Avatars, Banners, Posters)

This guide shows how to host public image uploads on your shared hosting (no Firebase Storage), and wire the ERP app to use it securely.

Recommended subdomain and structure
- Subdomain names (pick one):
  - uploads.erp.misk.org.in (recommended) or media.erp.misk.org.in
  - Avoid “ftp.” for end-user uploads; keep FTP as an admin-only protocol.
- Docroot structure (example):
  - / (subdomain root)
    - api/upload.php (the upload endpoint)
    - uploads/ (public files)
      - users/{uid}/photos/
      - initiatives/{initiativeId}/covers/
      - campaigns/{campaignId}/posters/
      - events/{eventId}/posters/

App contract (client → server)
- Method: POST multipart/form-data
- Fields:
  - file: the image file (required)
  - apiKey: shared secret string (required, simple mode)
  - dir: optional safe folder (e.g., users/abc123/photos) — server normalizes and creates if needed
- Response (success): JSON { "url": "https://uploads.erp.misk.org.in/uploads/users/abc123/photos/xyz.jpg" }
- Response (error): JSON { "error": "message" }

Security checklist (server)
- Require a secret apiKey in upload.php. Keep it private on the server; rotate periodically.
- Validate file size and type (jpg/png/webp); enforce a sane max (e.g., 2–3 MB).
- Generate a random filename; never trust client filename.
- Normalize and whitelist dir to prevent path traversal (.., leading /, etc.).
- Disable script execution in uploads/ via .htaccess (see below).
- Block directory listing in uploads/.
- Optionally add HMAC signatures with timestamp to reduce token leakage risk (advanced).

ERP app configuration (no code change required)
Run the app with dart-define flags:

```sh
flutter run \
  --dart-define=PHOTO_BACKEND=sharedHosting \
  --dart-define=SHARED_ENDPOINT_URL=https://uploads.erp.misk.org.in/api/upload.php \
  --dart-define=SHARED_API_KEY=SET_A_STRONG_SECRET
```

For Google Drive Apps Script backend (optional alternative):

```sh
flutter run \
  --dart-define=PHOTO_BACKEND=googleDrive \
  --dart-define=SHARED_ENDPOINT_URL=https://script.google.com/macros/s/AKfycb.../exec \
  --dart-define=DRIVE_FOLDER_ID=YOUR_DRIVE_FOLDER_ID \
  --dart-define=SHARED_API_KEY=SET_A_STRONG_SECRET
```

Deploy steps (cPanel/shared hosting)
1) Create a subdomain: uploads.erp.misk.org.in → docroot e.g., /home/USER/public_html/uploads.erp.misk.org.in
2) Create folders:
   - /api (for upload.php)
   - /uploads (public files)
3) Upload the sample upload.php (see server/upload.php in this repo) to /api/upload.php.
4) Edit upload.php and set the secret API_KEY.
5) Create .htaccess in /uploads with the rules below.
6) Optional: place a blank index.html in /uploads to prevent directory listing.
7) Test with curl:

```sh
curl -F "file=@avatar.jpg" -F "apiKey=SET_A_STRONG_SECRET" -F "dir=users/demo/photos" \
  https://uploads.erp.misk.org.in/api/upload.php
```

.htaccess (inside /uploads)
```
# Do not execute PHP in uploads
<FilesMatch "\\.(php|phar|phtml)$">
  Deny from all
</FilesMatch>

# Prevent directory listing (if not already disabled by server)
Options -Indexes
```

Folder naming suggestions
- users/{uid}/photos -> ERP avatars
- initiatives/{initiativeId}/covers -> initiative banner images
- campaigns/{campaignId}/posters -> campaign posters
- events/{eventId}/posters -> event posters

Advanced (optional HMAC)
- Client sends: apiKey, ts, sig where sig = HMAC_SHA256(ts + filename, SECRET)
- Server checks ts window (e.g., ±5 min) and recalculates sig.
- Adds replay protection and allows fast key rotation.

Troubleshooting
- 403/401: wrong apiKey or server WAF blocking large multipart; reduce file size or adjust ModSecurity rules.
- 500: check PHP error_log; ensure target folder is writable by PHP user.
- URL invalid: ensure subdomain DNS is live and docroot maps correctly.


## Shipping to Play Store (no hardcoding)

You don’t need to hardcode secrets. Inject them at build time with dart-define. The values become compile-time constants via String.fromEnvironment. Treat them as configuration, not true secrets (they can be extracted from the binary), and mitigate on the server (rate-limit, rotate keys, validate file types/sizes, optional HMAC/time window).

Build commands
- App Bundle (recommended for Play Store):
```sh
flutter build appbundle --release \\
  --dart-define=PHOTO_BACKEND=sharedHosting \\
  --dart-define=SHARED_ENDPOINT_URL=https://uploads.erp.misk.org.in/api/upload.php \\
  --dart-define=SHARED_API_KEY=YOUR_RELEASE_KEY
```
- APK (for side-loading/internal testing):
```sh
flutter build apk --release \\
  --dart-define=PHOTO_BACKEND=sharedHosting \\
  --dart-define=SHARED_ENDPOINT_URL=https://uploads.erp.misk.org.in/api/upload.php \\
  --dart-define=SHARED_API_KEY=YOUR_RELEASE_KEY
```

CI/CD (recommended)
Store these as CI secrets and pass to the build step. See .github/workflows/android_release.yml for a GitHub Actions example.

Mitigations and best practices
- Rotate SHARED_API_KEY periodically and on suspected leakage.
- Enforce server-side limits: content-type (jpg/png/webp), max size, random filenames.
- Optional: add HMAC(ts, filename) with short time window to reduce replay and static key exposure.
- Consider issuing short-lived upload tokens from a server/API you control instead of a static key (future hardening).
