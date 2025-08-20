Prerequisites
- Set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account JSON
- Install deps:

```
pip install -r scripts/requirements.txt
```

Core scripts
- reset_all_demo.py — backup (optional), wipe, and reseed core collections (idempotent)
  - Usage:
```
python scripts/reset_all_demo.py --seed-phase2 --seed-events --seed-demo-donations
```
  - Options:
    - --no-backup: skip JSON backups
    - --skip-auth-sync: don’t sync Firebase Auth users to Firestore
    - --seed-phase2: run scripts/seed_masjid_phase2.py (initiatives/campaigns/tasks/donations)
    - --seed-events: run scripts/seed_events_announcements.py (events/announcements)
    - --seed-demo-donations: run scripts/seed_demo_donations.py (demo donations dataset)

- seed_masjid_phase2.py — Phase 2 seeds (initiatives/campaigns/tasks/donations)
  - Idempotent by seedKey; includes cleanup of legacy duplicates
  - Run:
```
python scripts/seed_masjid_phase2.py
```

- seed_events_announcements.py — idempotent seed for Events & Announcements
  - Links sample items to the first initiative if available
```
python scripts/seed_events_announcements.py --link-to-first-initiative
```

- seed_demo_donations.py — demo donations dataset (module-specific seed)
  - Ensures a Demo initiative + campaign; upserts donations by seedKey; optional cleanup by seedTag
```
python scripts/seed_demo_donations.py --clean
```

Existing/utility scripts
- reset_and_seed_firestore.py — legacy reset/seed; kept for reference
- seed_permissions.py — seed permissions collection
- check_firebase_status.py — quick Firestore dump
- wipe_domain_collections.py — targeted collection wipe

Demo reset workflow
1) Optional backup + full reset:
```
python scripts/reset_all_demo.py --seed-phase2 --seed-events --seed-demo-donations
```
2) Re-run any module seeders independently as needed (all are idempotent):
```
python scripts/seed_masjid_phase2.py
python scripts/seed_events_announcements.py --link-to-first-initiative
python scripts/seed_demo_donations.py --clean
```

Notes
- Seeds avoid duplicates using natural keys (name/title) or seedKey/seedTag.
- Prefer “edit-first testing” with seeded data; create flows can be tested after edit passes.
