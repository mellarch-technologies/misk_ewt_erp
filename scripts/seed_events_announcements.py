"""
Seed Events & Announcements (idempotent by title)

Usage:
  python scripts/seed_events_announcements.py [--link-to-first-initiative]

Prereqs:
  - Set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account JSON
  - pip install -r scripts/requirements.txt
"""
import argparse
import sys
from datetime import datetime, timedelta

import firebase_admin
from firebase_admin import credentials
from google.cloud import firestore


def upsert_event(db, title: str, description: str, type_: str, when: datetime, public=True, featured=False, initiative_ref=None):
    col = db.collection('event_announcements')
    q = col.where('title', '==', title).limit(1).get()
    data = {
        'title': title,
        'description': description,
        'type': type_,
        'eventDate': firestore.SERVER_TIMESTAMP if when is None else when,
        'publicVisible': public,
        'featured': featured,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }
    if initiative_ref is not None:
        data['initiative'] = initiative_ref
    if len(q) == 0:
        data['createdAt'] = firestore.SERVER_TIMESTAMP
        col.add(data)
        print(f"Created: {title}")
    else:
        col.document(q[0].id).update(data)
        print(f"Updated: {title}")


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('--link-to-first-initiative', action='store_true', help='Link samples to the first initiative if available')
    args = parser.parse_args(argv)

    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred)
    db = firestore.Client()

    initiative_ref = None
    if args.link_to_first_initiative:
        inits = db.collection('initiatives').limit(1).get()
        if len(inits) > 0:
            initiative_ref = inits[0].reference
            print(f"Will link to initiative: {inits[0].to_dict().get('title', inits[0].id)}")
        else:
            print("No initiatives found; proceeding without linking.")

    now = datetime.utcnow()
    samples = [
        ("Monthly Community Meet", "Open forum and updates for members.", "event", now + timedelta(days=7), True, True),
        ("Quarterly Report Published", "Summary of initiatives and donations this quarter.", "announcement", now, True, False),
        ("Volunteer Drive", "Join our volunteer onboarding.", "event", now + timedelta(days=14), True, False),
        ("Office Closed Notice", "Office closed on public holiday.", "announcement", now + timedelta(days=3), True, False),
    ]

    for title, desc, type_, when, pub, feat in samples:
        upsert_event(db, title, desc, type_, when, public=pub, featured=feat, initiative_ref=initiative_ref)

    print("Seeded Events & Announcements (idempotent).")


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]) or 0)

