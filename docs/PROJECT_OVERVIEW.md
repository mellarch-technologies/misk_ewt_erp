# MISK ERP Mini — Project Overview

Purpose
- Single source of truth for project vision, scope, architecture, data model, automation, and current status.
- Use this alongside project_log.md (chronological log). This file is evergreen; the log tracks timeline.

Vision & Goals
- Build a modular, cloud-based ERP for MISK (internal first, public app later).
- Deliver secure Authentication, Roles & Permissions, and core operational modules (Initiatives, Campaigns, Tasks, Events/Announcements).
- Prioritize automation, reproducibility, and industry-standard security.

Architecture
- Client: Flutter (Dart), Provider for state management, theming in theme/.
- Backend: Firebase (Auth, Firestore, Analytics, Crashlytics).
- Automation: Python scripts under scripts/ for Firestore seeding, backup, and status checks.
- Data: Firestore with collections users, roles, permissions, initiatives, campaigns, tasks, events_announcements, plus auth_audit.

Auth & Security (current)
- Email/password auth with redirect fix.
- Client-side login throttling/lockout (5 attempts → 5-minute lock) with countdown UI.
- AuditService logs auth events to auth_audit.
- App Lock foundation (Phase 2): secure PIN storage (sha256, flutter_secure_storage), idle timeout, lock gate/UI.
- Planned: lock on background, re-auth for sensitive actions, optional biometrics, hardened Firestore rules.

Roles & Permissions
- permissions collection is dynamic (keys like can_manage_users). New permissions require no app code changes.
- roles documents: { name, permissions: Map<String,bool>, protected, description, createdBy, updatedBy, createdAt, updatedAt }.
- users documents: includes roleId (DocumentReference), isSuperAdmin, and profile fields.
- PermissionProvider enforces role permissions; Super Admin override.

Key Data Models (high level)
- users: uid, name, email, roleId (DocumentReference to roles), isSuperAdmin, designation, occupation, phone, address, allowPhotoUpload, createdAt, gender, photo, qualification, status.
- roles: id, name, permissions (Map<String,bool>), protected, description, createdBy/updatedBy, createdAt/updatedAt.
- permissions: id, key, description (optional) — used to drive dynamic UI.
- initiatives/campaigns/tasks/events_announcements: simple CRUD; details evolving with MVP.
- auth_audit: type (login/logout/password_reset_request), email/uid, success, errorCode, timestamp.

Automation Scripts (scripts/)
- check_firebase_status.py — lists collections and samples.
- seed_permissions.py — seeds permissions.
- reset_and_seed_firestore.py — backup, wipe, and reseed key collections.
- backup_* — JSON backups per collection.
- Requires GOOGLE_APPLICATION_CREDENTIALS set to service account key; uses google-cloud-firestore.

Testing
- Unit: PermissionProvider (super admin override, map checks, clear state).
- Widget: Dashboard tests aligned with current UI via fakes (no Firebase init).
- Planned: mocked FirebaseAuth auth-flow tests, permission-gated UI tests.

Current Status (summary)
- Phase 1 complete: Auth flows stable, Roles & Permissions dynamic, automation scripts in place, basic modules scaffolded.
- Phase 2 in progress: App Lock, audit logs, session hardening; upcoming idle/background lock, re-auth for sensitive actions, error UX helper, biometric unlock integration.

Next Steps (Phase 2)
- Session management: idle timeout enforcement, background lock.
- Re-auth for sensitive actions (role changes, user deletion, security settings).
- Error/UX polish: centralized snackbar/toast helper and consistent empty/error states.
- Optional MFA hooks: email OTP/biometric toggle scaffolding.

How To Use In New Chats
- Say: "Read project_log.md and docs/PROJECT_OVERVIEW.md, then continue from Next Steps. Keep answers short. Update project_log.md as you proceed."
- If deeper module planning is needed, also mention: chat_scripts/MISK_Initiatives_ERP_Mini.xlsx and chat_scripts/misk_modules_v1.0.

File Pointers
- Project log (chronological): project_log.md
- Overview (evergreen): docs/PROJECT_OVERVIEW.md
- Chats and module lists: chat_scripts/
- Firebase rules: firebase/firestore.rules
- Automation: scripts/

