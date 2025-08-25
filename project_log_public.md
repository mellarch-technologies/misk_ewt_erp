# Public App Log: MiSK EWT App

## Version: Public App Scaffold + Parallel Plan (2025-08-24)

Summary
- Repo uses a single Flutter project with two entrypoints:
  - ERP (internal): lib/main.dart (package: com.miskewt.erp)
  - Public (donor-facing): lib/public_main.dart (package: com.miskewt.misk)
- Public app scaffolded with Donate flows and service stub; ready to wire Firebase and live Payment Settings.
- We will publish two separate Play Store listings (ERP and Public) using flavors/targets.

Scope Note (2025-08-24)
- Public app is holistic (not only donations). It will include public browsing of initiatives/campaigns, events/announcements feed, updates, transparent progress, optional volunteer/contact flows, and later Razorpay checkout.
- Roadmap context is in chat_scripts/perplexity (see the latest Perplexity sessions). This log will track scope and milestones as they ship.

What Exists Now
- Entry: lib/public_main.dart
- Screens:
  - lib/public_app/screens/donate_home_screen.dart
  - lib/public_app/screens/bank_transfer_screen.dart
  - lib/public_app/screens/upi_screen.dart
- Service stub: lib/public_app/services/public_donation_service.dart
- Shared theme/components with ERP (MiskTheme, Common widgets where applicable)

Build/Run
- ERP: flutter run -t lib/main.dart
- Public: flutter run -t lib/public_main.dart
- See docs/RUN_CONFIGS.md for flavors and dart-define examples (upload adapter, etc.).

Firebase
- One Firebase project; two app registrations (Android/iOS):
  - ERP: com.miskewt.erp (existing)
  - Public: com.miskewt.misk (exists per session)
- Next: generate public_firebase_options.dart via FlutterFire and initialize Firebase in lib/public_main.dart (ERP already uses lib/firebase_options.dart).

Android & iOS Packaging
- Android: add productFlavors (erp/public) with different applicationId (com.miskewt.erp, com.miskewt.misk) and place google-services.json per flavor.
- iOS: add second target/scheme for Public, bundle ID com.miskewt.misk, with its own GoogleService-Info.plist.

MVP Scope (Public)
- Donation methods: Bank Transfer (recommended), UPI (VPA/QR), Razorpay (later).
- Form validation: PAN+Address required when amount ≥ ₹10,000.
- Writes: create donations with status=pending and method; ERP reconciles later.
- Payment Settings: pull from Firestore Settings.payments to render Bank/UPI details.

Next Steps
1) Generate and wire public_firebase_options.dart; init in public_main.dart.
2) Implement PublicDonationService Firestore writes (status=pending) + Firestore rules for safe public writes.
3) Read and render Settings.payments on Public flows (replace placeholders).
4) Optional: Razorpay order/webhook integration (confirmed status), QR rendering for UPI, and receipt upload adapter.

Notes
- Keep shared code centralized; public-specific UI under lib/public_app. Revisit modularization later if coupling grows.
- Two independent app store releases are planned; CI/CD can build both via flavors and separate tracks.

## [2025-08-24] Public App — Pending Donations + Settings Read, Handoff

What changed
- PublicDonationService now writes sanitized pending donations to `public_pending_donations` with server timestamps.
- Public Bank/UPI screens read live Payment Settings (settings/payments) for bank details, VPA, QR.
- Firestore rules updated to allow safe unauthenticated create for `public_pending_donations`; admins can read/update/delete.
- UI deprecations cleaned (withOpacity → withValues) in shared widgets.

Validation
- Static checks: PASS on modified public and shared files.
- Manual: Bank/UPI forms submit and show success snackbar; docs appear under `public_pending_donations`.

Next steps (handoff)
- Generate `public_firebase_options.dart` and switch init in `lib/public_main.dart` (now pointing to ERP options).
- Optional: Razorpay order/webhook integration; UPI QR rendering polish.
- Keep shared components centralized; consider flavors for packaging (already documented in RUN_CONFIGS.md).

## [2025-08-25] Public Home Scaffold

What
- Added PublicHomeScreen (app bar + tiles for Initiatives/Campaigns/Events + Donate Now CTA to DonateHomeScreen).
- Updated lib/public_main.dart to set PublicHomeScreen as the home widget.
- Firebase init continues via PublicFirebaseOptions (bridge to DefaultFirebaseOptions) until FlutterFire generates public_firebase_options.dart for com.miskewt.misk.

Validation
- Static checks: public_main.dart and PublicHomeScreen compile (only a pubspec-edited warning is reported by analyzer tooling).

Next (1–2 days)
- Generate public_firebase_options.dart via FlutterFire and switch init.
- Add placeholder list screens: PublicInitiativesListScreen, PublicCampaignsListScreen, PublicEventsListScreen.
- Read Payment Settings to surface UPI QR/bank details in Donate flows.
