"""
Script: reset_and_seed_firestore.py

This script will:
1. Backup all specified Firestore collections to JSON files (if not already backed up).
2. Delete all documents from those collections.
3. Sync all Firebase Auth users to the Firestore users collection (using your user model fields).
4. Seed the permissions and roles collections with default data.
5. Assign Super Admin role to admin@misk.org.in and create other roles (Trustee, Member, Associate, Staff).

Usage:
  python scripts/reset_and_seed_firestore.py

Requirements:
- google-cloud-firestore
- firebase-admin
- Service account key JSON (set GOOGLE_APPLICATION_CREDENTIALS env variable)
"""

import json
import os
from google.cloud import firestore
import firebase_admin
from firebase_admin import credentials, auth
import sys

COLLECTIONS_TO_RESET = [
    'users',
    'roles',
    'permissions',
    'initiatives',
    'members',
]

DEFAULT_PERMISSIONS = [
    'can_manage_users',
    'can_view_finances',
    'can_manage_events',
    'can_view_reports',
    'can_edit_profile',
    'can_manage_roles',
    'can_manage_settings',
    'can_view_all_modules',
]

DEFAULT_ROLES = [
    {
        'name': 'Super Admin',
        'permissions': {p: True for p in DEFAULT_PERMISSIONS},
        'protected': True,
        'description': 'Full access to all modules and settings.',
    },
    {
        'name': 'Trustee',
        'permissions': {
            'can_view_finances': True,
            'can_manage_events': True,
            'can_manage_settings': True,
            'can_view_all_modules': True,
            'can_manage_roles': True,
        },
        'protected': True,
        'description': 'Trustee with access to key modules.',
    },
    {
        'name': 'Member',
        'permissions': {
            'can_view_reports': True,
            'can_edit_profile': True,
        },
        'protected': False,
        'description': 'General member with limited access.',
    },
    {
        'name': 'Associate',
        'permissions': {
            'can_edit_profile': True,
        },
        'protected': False,
        'description': 'Associate with basic profile access.',
    },
    {
        'name': 'Staff',
        'permissions': {
            'can_manage_users': True,
            'can_manage_events': True,
            'can_manage_settings': True,
            'can_view_all_modules': True,
        },
        'protected': False,
        'description': 'Staff with operational access.',
    },
]

USER_MODEL_FIELDS = [
    'uid', 'name', 'email', 'roleId', 'isSuperAdmin', 'designation', 'occupation', 'phone', 'address',
    'allowPhotoUpload', 'createdAt', 'gender', 'photo', 'qualification', 'status'
]

BACKUP_DIR = 'scripts/'

def backup_collection(db, collection_name):
    docs = db.collection(collection_name).stream()
    data = [{"id": doc.id, **doc.to_dict()} for doc in docs]
    with open(os.path.join(BACKUP_DIR, f'backup_{collection_name}.json'), 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, default=str)
    print(f"Backed up {len(data)} documents from '{collection_name}' to scripts/backup_{collection_name}.json")

def delete_collection(db, collection_name):
    docs = db.collection(collection_name).stream()
    count = 0
    for doc in docs:
        doc.reference.delete()
        count += 1
    print(f"Deleted {count} documents from '{collection_name}'")

def seed_permissions(db):
    col = db.collection('permissions')
    for perm in DEFAULT_PERMISSIONS:
        col.document(perm).set({'key': perm})
    print("Seeded permissions.")

def seed_roles(db):
    col = db.collection('roles')
    role_refs = {}
    for role in DEFAULT_ROLES:
        doc_ref = col.document()
        role_data = {
            'name': role['name'],
            'permissions': role['permissions'],
            'protected': role['protected'],
            'description': role['description'],
            'createdBy': 'system',
            'updatedBy': 'system',
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }
        doc_ref.set(role_data)
        role_refs[role['name']] = doc_ref.id
    print("Seeded roles.")
    return role_refs

def sync_auth_users_to_firestore(db, role_refs):
    users_ref = db.collection('users')
    all_auth_users = auth.list_users().iterate_all()
    count = 0
    for user in all_auth_users:
        user_data = {
            'uid': user.uid,
            'name': user.display_name or '',
            'email': user.email or '',
            'roleId': None,
            'isSuperAdmin': False,
            'designation': '',
            'occupation': '',
            'phone': user.phone_number or '',
            'address': '',
            'allowPhotoUpload': False,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'gender': '',
            'photo': user.photo_url or '',
            'qualification': '',
            'status': '',
        }
        if user.email == 'admin@misk.org.in':
            user_data['isSuperAdmin'] = True
            user_data['roleId'] = db.collection('roles').document(role_refs.get('Super Admin'))
            user_data['name'] = 'Super Admin'
        elif user.email and user.email.startswith('trustee@'):
            user_data['roleId'] = db.collection('roles').document(role_refs.get('Trustee'))
            user_data['name'] = 'Trustee'
        elif user.email and user.email.startswith('member@'):
            user_data['roleId'] = db.collection('roles').document(role_refs.get('Member'))
            user_data['name'] = 'Member'
        elif user.email and user.email.startswith('associate@'):
            user_data['roleId'] = db.collection('roles').document(role_refs.get('Associate'))
            user_data['name'] = 'Associate'
        elif user.email and user.email.startswith('staff@'):
            user_data['roleId'] = db.collection('roles').document(role_refs.get('Staff'))
            user_data['name'] = 'Staff'
        users_ref.document(user.uid).set(user_data)
        count += 1
    print(f"Synced {count} Auth users to Firestore users collection.")

def main():
    try:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)
        db = firestore.Client()
        print("Firebase initialized.")
        for col in COLLECTIONS_TO_RESET:
            print(f"Backing up {col}...")
            backup_collection(db, col)
        for col in COLLECTIONS_TO_RESET:
            print(f"Deleting {col}...")
            delete_collection(db, col)
        print("Seeding permissions...")
        seed_permissions(db)
        print("Seeding roles...")
        role_refs = seed_roles(db)
        print("Syncing Auth users to Firestore...")
        sync_auth_users_to_firestore(db, role_refs)
        print("Reset and reseed complete.")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
