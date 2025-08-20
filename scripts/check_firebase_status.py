"""
Script: check_firebase_status.py

This script connects to your Firestore project and prints out:
- All top-level collections
- A sample of documents from each collection
- (Optionally) Firebase project settings if accessible via Admin SDK

Usage:
  python scripts/check_firebase_status.py

Requirements:
- google-cloud-firestore
- google-cloud-core
- Service account key JSON (set GOOGLE_APPLICATION_CREDENTIALS env variable)
"""

import os
from google.cloud import firestore
from google.api_core.exceptions import GoogleAPIError


def print_collections_and_samples(db, sample_limit=3):
    print("\nTop-level Firestore collections:")
    collections = list(db.collections())
    if not collections:
        print("  (No collections found)")
        return
    for col in collections:
        print(f"- {col.id}")
        docs = list(col.limit(sample_limit).stream())
        if docs:
            for doc in docs:
                print(f"    Doc ID: {doc.id} | Data: {doc.to_dict()}")
        else:
            print("    (No documents)")


def main():
    try:
        db = firestore.Client()
        print("Connected to Firestore.")
        print_collections_and_samples(db)
        # Note: Project settings (like auth, rules, etc.) are not accessible via Firestore SDK.
        # For more, use Firebase CLI or Console.
    except GoogleAPIError as e:
        print(f"Firestore error: {e}")
    except Exception as ex:
        print(f"Error: {ex}")


if __name__ == "__main__":
    main()

