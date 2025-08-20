"""
Script: seed_permissions.py

This script seeds the Firestore 'permissions' collection with a set of default permissions.

Usage:
  python scripts/seed_permissions.py

Requirements:
- google-cloud-firestore
- Service account key JSON (set GOOGLE_APPLICATION_CREDENTIALS env variable)
"""

from google.cloud import firestore

DEFAULT_PERMISSIONS = [
    'can_manage_users',
    'can_view_finances',
    'can_manage_events',
    'can_view_reports',
    'can_edit_profile',
    'can_manage_roles',
    # Add more default permissions as needed
]

def seed_permissions():
    db = firestore.Client()
    col = db.collection('permissions')
    for perm in DEFAULT_PERMISSIONS:
        doc_ref = col.document(perm)
        doc_ref.set({'key': perm})
        print(f"Seeded permission: {perm}")
    print("Seeding complete.")

if __name__ == "__main__":
    seed_permissions()

