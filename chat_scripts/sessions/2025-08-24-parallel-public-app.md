# Session Log — Parallel Public App Plan & ERP Tweaks (2025-08-24)

Context
- Goal: Run ERP (internal) and Public donor app in parallel from one repo, ship faster, keep code shared.
- Repo: single Flutter project with two entrypoints — ERP (lib/main.dart) and Public (lib/public_main.dart).

Decisions & Confirmations
- Play Store: YES, we will publish two separate apps (two listings):
  - ERP app nickname: MISK EWT ERP — package: com.miskewt.erp
  - Public app nickname: MiSK EWT App — package: com.miskewt.misk
  - Android: use productFlavors (erp/public) to create distinct applicationId/bundles.
  - iOS: two targets/schemes with distinct bundle IDs.
  - Firebase: one project, two app registrations, separate options files; both can share the same Firestore database and rules.
- Repo structure stays single; shared models/services; separate Firebase init per entrypoint.

What shipped today
- Public app scaffold:
  - Entry: lib/public_main.dart
  - Screens: DonateHome, BankTransfer, UPI (with validated forms)
  - Service stub: PublicDonationService (submitPendingDonation)
- ERP stability & UX:
  - 20-per-page pagination across Users, Initiatives, Campaigns, Donations, Tasks, Events.
  - Reduced banner heights on cards; KPI grid adjusts to narrow widths; fixed minor overflow.
- Logs: project_log.md updated with today’s plan and instructions.

How to run now
- ERP: flutter run -t lib/main.dart
- Public: flutter run -t lib/public_main.dart

Next steps (high priority)
1) Firebase: add Public Android/iOS apps in Firebase (package/bundle IDs above) and download configs.
2) Generate public_firebase_options.dart and init Firebase in public_main.dart.
3) Android flavors: add erp/public flavors; place google-services.json per flavor; set applicationId.
4) iOS: add second target/scheme with bundle ID com.miskewt.misk and GoogleService-Info.plist.
5) Implement PublicDonationService Firestore writes (status=pending) + tighten Firestore rules.
6) Public UI: read Payment Settings from Firestore (bank/UPI), Razorpay later.

Notes
- Keep keystores/signing secure; flavors can share signing config if policy allows, otherwise separate.
- CI can build two artifacts via flavors/targets; release tracks are independent in Play Console/App Store Connect.

---

## Follow-up — Dashboard UX (Scoped KPIs + Compact Sliders)

User feedback (ERP Dashboard)
- KPI for “featured initiative” should be selectable: add Initiative/Campaign selector and default to a sensible initiative.
- Cards in sliders (Initiatives/Campaigns) were banner-heavy; reduce banner and show more data.
- Keep KPI cards in two columns on phones; Tasks section should support toggling views (list/grid/table later).
- Continue with pagination, Payment Settings E2E, Donations reconciliation polish, and stability fixes.

Shipped now
- Scoped KPIs: Initiative and optional Campaign dropdowns drive donations trend and task breakdown.
- Default initiative auto-select (prefers titles containing “Masjid”, else first).
- Compact slider cards for Initiatives/Campaigns (thumbnail + content) replacing banner-dominant layout.
- KPI grid keeps two columns on most phones; Tasks already supports list/grid toggle.

Files
- lib/screens/dashboard_screen.dart
- lib/widgets/initiative_card.dart (compact mode)
- lib/widgets/campaign_card.dart (compact mode)

Quality
- Static analyzer: PASS (no errors; one benign warning on an unused field).

Resume Checklist (active)
- ERP (1–2 days):
  1) Payment Settings E2E manual QA and bugfixes; wire any missing labels to Firestore settings. 
  2) Donations reconciliation polish (bulk + quick actions validated) — a final smoke pass.
  3) Dashboard: persist last selected initiative/campaign; add small trend badges to KPIs.
  4) Tasks: explore table view prototype (read-only) with column resize on wide screens.
- Public (1–2 days):
  1) public_firebase_options.dart generation + Firebase.init in public_main.dart.
  2) Implement PublicDonationService writes (status=pending) + Firestore rules.
  3) Render Payment Settings (bank/UPI) on public flows.

Author: GitHub Copilot

---

## Decision — Keep Dashboard v1 + UX Plan (RenderFlex fix shipped)

Summary
- Decision: Keep Dashboard v1 as primary. Dashboard v2 (sliver) stays under Drawer → Labs for comparison only.
- Fix shipped: Responsive Initiative/Campaign selector (stacks on narrow, Flexible on wide) to remove RenderFlex overflows.
- Sliders: Keep compact thumbnail-left cards (already live) to avoid banner-heavy UI.

KPI & Cards Plan
- Extract KpiCard widget + config (metric, collection, filters, format, permissionKey).
- KPIs to include: Active Members, Roles, Initiatives, Campaigns, Open Tasks, Upcoming Events, Donations (Confirmed/Reconciled) with small trend badges.
- Scope KPIs by current Initiative/Campaign (persist last selection locally).
- Tasks on dashboard: micro-list with quick filters; optional micro-board (3 lanes) as a toggle later.

Why
- Avoids heavy headers and overflow; enables quick, configurable KPIs tied to the current context, aligned with ERP workflows.

Next Steps (1–2 days)
1) Extract KpiCard + config and refactor current KPIs to use it.
2) Persist last Initiative/Campaign selection.
3) Add tiny trend badges to KPI tiles.
4) Optional: Tasks micro-board toggle (read-only) for a PM-style glance.

Status
- Static analyzer: PASS across dashboard changes (only benign unused-field warning in v1).
- Public app testing continues on real device; logs kept in this session and project_log.md.
