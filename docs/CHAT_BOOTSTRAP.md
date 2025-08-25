# Chat Bootstrap — Quick Resume Template

Use this template when starting a fresh chat so I can pick up exactly where we left off with full context.

## 1) Copy-paste this Prompt

Paste the prompt below at the start of a new chat, then attach the listed files.

---
Prompt:

Read and ingest these files completely, then continue the work exactly from the latest Resume Checklist.

Primary logs:
- project_log.md (ERP)
- project_log_public.md (Public App)
- Latest session log in chat_scripts/sessions (pick the most recent by date)

Repo path: E:/MiSK/app/misk_ewt_erp

Then:
- Summarize the latest status in 5 bullets.
- List the immediate Next Steps for both ERP and Public (1–2 days scope).
- Execute the next item end-to-end (edits + static checks).

---

## 2) Attach These Files
- E:/MiSK/app/misk_ewt_erp/project_log.md
- E:/MiSK/app/misk_ewt_erp/project_log_public.md
- Latest session under E:/MiSK/app/misk_ewt_erp/chat_scripts/sessions/*.md (by date)
- If relevant: any error logs or CI outputs from the last run

## 3) Current Resume Checklist (Live)

Backend (ERP) — immediate
- Android flavors: add erp/public applicationId, place google-services.json per flavor.
- iOS scheme/target for Public: bundle ID com.miskewt.misk, GoogleService-Info.plist.
- Manual QA: Payment Settings E2E and Donations reconciliation flow.

Public App — immediate
- Firebase wiring: generate public_firebase_options.dart; init in lib/public_main.dart.
- PublicDonationService: write donations (status=pending) and tighten Firestore rules.
- Read Settings.payments from Firestore (replace placeholders on Bank/UPI screens).

## 4) How to Run
- ERP: `flutter run -t lib/main.dart`
- Public: `flutter run -t lib/public_main.dart`

## 5) Tips
- If you hit token limits, just paste this same prompt again with the 3 files above; I’ll re-sync state and continue.
- Keep logs current after each meaningful change (project_log.md, project_log_public.md, and session log).

