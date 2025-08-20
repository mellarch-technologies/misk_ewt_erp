"""
Script: wipe_domain_collections.py

Deletes all documents from domain collections only (does NOT touch users/roles/permissions):
- initiatives
- campaigns
- tasks
- events_announcements

Usage:
  python scripts/wipe_domain_collections.py

Requirements:
- google-cloud-firestore
- Service account key JSON (set GOOGLE_APPLICATION_CREDENTIALS env variable)
"""

from google.cloud import firestore
from google.api_core.exceptions import GoogleAPIError

DOMAIN_COLLECTIONS = [
    "initiatives",
    "campaigns",
    "tasks",
    "events_announcements",
]


def delete_collection(db, collection_name: str) -> int:
    docs = list(db.collection(collection_name).stream())
    for d in docs:
        d.reference.delete()
    return len(docs)


def main():
    try:
        db = firestore.Client()
        print("Connected to Firestore. Wiping domain collections...")
        for col in DOMAIN_COLLECTIONS:
            count = delete_collection(db, col)
            print(f"Deleted {count} documents from '{col}'")
        print("Done.")
    except GoogleAPIError as e:
        print(f"Firestore error: {e}")
    except Exception as ex:
        print(f"Error: {ex}")


if __name__ == "__main__":
    main()

