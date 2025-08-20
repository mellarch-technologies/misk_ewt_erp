"""
Script: print_domain_counts.py

Prints document counts for domain collections to confirm wipe/seed operations.

Usage:
  python scripts/print_domain_counts.py

Requirements:
- google-cloud-firestore
- Service account key JSON (set GOOGLE_APPLICATION_CREDENTIALS env variable)
"""

from google.cloud import firestore

def count_col(db, name):
    return len(list(db.collection(name).limit(1000).stream()))


def main():
    db = firestore.Client()
    cols = [
        'initiatives', 'campaigns', 'tasks', 'events_announcements',
        'users', 'roles', 'permissions'
    ]
    print("Collection counts:")
    for c in cols:
        try:
            print(f"- {c}: {count_col(db, c)}")
        except Exception as e:
            print(f"- {c}: error ({e})")

if __name__ == '__main__':
    main()

