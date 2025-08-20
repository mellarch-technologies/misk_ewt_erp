"""
Script: backup_firestore_collections.py

This script backs up all documents from specified Firestore collections to JSON files.

Usage:
  python scripts/backup_firestore_collections.py

Requirements:
- google-cloud-firestore
- Service account key JSON (set GOOGLE_APPLICATION_CREDENTIALS env variable)

Backups are saved as: backup_<collection>.json in the scripts/ folder.
"""

import json
from google.cloud import firestore

COLLECTIONS_TO_BACKUP = [
    'users',
    'roles',
    'permissions',
    'initiatives',
    'members',
]

def backup_collection(db, collection_name):
    docs = db.collection(collection_name).stream()
    data = [{"id": doc.id, **doc.to_dict()} for doc in docs]
    with open(f'scripts/backup_{collection_name}.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, default=str)
    print(f"Backed up {len(data)} documents from '{collection_name}' to scripts/backup_{collection_name}.json")

def main():
    db = firestore.Client()
    for col in COLLECTIONS_TO_BACKUP:
        backup_collection(db, col)
    print("Backup complete.")

if __name__ == "__main__":
    main()

