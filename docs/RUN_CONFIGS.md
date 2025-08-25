# Run Configs — ERP and Public Apps

Use these settings in your IDE Run/Debug configurations or the CLI to run/build each app separately.

ERP (Internal)
- Dart entry point: lib/main.dart
- Flavor: erp
- Additional Run Args:
  --flavor erp
  -t lib/main.dart
  --dart-define=PHOTO_BACKEND=sharedHosting
  --dart-define=SHARED_ENDPOINT_URL=https://uploads.erp.misk.org.in/api/upload.php
  --dart-define=SHARED_API_KEY=<YOUR_SHARED_API_KEY>
- Additional Attach Args (optional):
  flutter attach --device-id <deviceId>
- Build commands:
  flutter build appbundle --flavor erp -t lib/main.dart \
    --dart-define=PHOTO_BACKEND=sharedHosting \
    --dart-define=SHARED_ENDPOINT_URL=https://uploads.erp.misk.org.in/api/upload.php \
    --dart-define=SHARED_API_KEY=<YOUR_SHARED_API_KEY>

Public (Donor App)
- Dart entry point: lib/public_main.dart
- Flavor: public
- Additional Run Args:
  --flavor public
  -t lib/public_main.dart
  --dart-define=PHOTO_BACKEND=sharedHosting
  --dart-define=SHARED_ENDPOINT_URL=https://uploads.erp.misk.org.in/api/upload.php
  --dart-define=SHARED_API_KEY=<YOUR_SHARED_API_KEY>
- Additional Attach Args (optional):
  flutter attach --device-id <deviceId>
- Build commands:
  flutter build appbundle --flavor public -t lib/public_main.dart \
    --dart-define=PHOTO_BACKEND=sharedHosting \
    --dart-define=SHARED_ENDPOINT_URL=https://uploads.erp.misk.org.in/api/upload.php \
    --dart-define=SHARED_API_KEY=<YOUR_SHARED_API_KEY>

Android flavors
- erp: applicationId com.miskewt.erp (app name: MISK EWT ERP)
- public: applicationId com.miskewt.misk (app name: MiSK EWT App)
- Firebase configs:
  - android/app/src/erp/google-services.json
  - android/app/src/public/google-services.json

iOS targets/schemes
- Create a second target/scheme for Public with bundle ID com.miskewt.misk.
- Add the matching GoogleService-Info.plist to the Public target.

Notes
- Upload settings via dart-define enable the shared-hosting upload adapter in both apps.
- For CI/CD, use separate jobs per flavor and entrypoint.
