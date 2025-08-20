"""
Reset all core Firestore collections and seed demo data (idempotent upserts).

Usage:
  python scripts/reset_all_demo.py [--no-backup] [--skip-auth-sync] [--seed-events] [--seed-phase2] [--seed-demo-donations]

Flags:
  --no-backup       Skip JSON backup before delete (faster, not recommended)
  --skip-auth-sync  Do not sync Firebase Auth users to Firestore users
  --seed-events     Seed Events/Announcements sample items
  --seed-phase2     Attempt to run scripts/seed_masjid_phase2.py for initiatives/campaigns/tasks/donations
  --seed-demo-donations  Run scripts/seed_demo_donations.py to seed a clean Demo Donations dataset

Prereqs:
  - Set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account JSON
  - pip install -r scripts/requirements.txt
"""
import argparse
import json
import os
import subprocess
import sys

import firebase_admin
from firebase_admin import credentials, auth
from google.cloud import firestore

COLLECTIONS = [
    'users',
    'roles',
    'permissions',
    'initiatives',
    'campaigns',
    'tasks',
    'donations',
    'event_announcements',
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

BACKUP_DIR = 'scripts'


def backup_collection(db, collection_name):
    docs = db.collection(collection_name).stream()
    data = [{"id": d.id, **d.to_dict()} for d in docs]
    path = os.path.join(BACKUP_DIR, f'backup_{collection_name}.json')
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, default=str)
    print(f"Backed up {len(data)} docs from {collection_name} -> {path}")


def delete_collection(db, collection_name):
    batch = db.batch()
    count = 0
    for d in db.collection(collection_name).stream():
        batch.delete(d.reference)
        count += 1
        if count % 400 == 0:
            batch.commit()
            batch = db.batch()
    if count % 400 != 0:
        batch.commit()
    print(f"Deleted {count} docs from {collection_name}")


def seed_permissions(db):
    col = db.collection('permissions')
    for perm in DEFAULT_PERMISSIONS:
        col.document(perm).set({'key': perm})
    print('Seeded permissions.')


def seed_roles(db):
    col = db.collection('roles')
    # Upsert by name (idempotent)
    for role in DEFAULT_ROLES:
        q = col.where('name', '==', role['name']).limit(1).get()
        data = {
            'name': role['name'],
            'permissions': role['permissions'],
            'protected': role['protected'],
            'description': role['description'],
            'updatedAt': firestore.SERVER_TIMESTAMP,
            'updatedBy': 'system',
        }
        if not q:
            data['createdAt'] = firestore.SERVER_TIMESTAMP
            data['createdBy'] = 'system'
            col.add(data)
        else:
            col.document(q[0].id).update(data)
    print('Seeded roles.')


def sync_auth_users_to_firestore(db):
    users_ref = db.collection('users')
    count = 0
    for user in auth.list_users().iterate_all():
        data = {
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
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }
        # Assign default roles by email prefix
        email = (user.email or '').lower()
        roles = list(db.collection('roles').where('name', 'in', ['Super Admin','Trustee','Member','Associate','Staff']).stream())
        role_by_name = {r.to_dict().get('name'): r.reference for r in roles}
        if email == 'admin@misk.org.in':
            data['isSuperAdmin'] = True
            data['roleId'] = role_by_name.get('Super Admin')
            data['name'] = 'Super Admin'
        elif email.startswith('trustee@'):
            data['roleId'] = role_by_name.get('Trustee')
            data['name'] = 'Trustee'
        elif email.startswith('member@'):
            data['roleId'] = role_by_name.get('Member')
            data['name'] = 'Member'
        elif email.startswith('associate@'):
            data['roleId'] = role_by_name.get('Associate')
            data['name'] = 'Associate'
        elif email.startswith('staff@'):
            data['roleId'] = role_by_name.get('Staff')
            data['name'] = 'Staff'
        users_ref.document(user.uid).set(data)
        count += 1
    print(f"Synced {count} Auth users to users collection.")


def maybe_run_seed_phase2():
    path = os.path.join('scripts', 'seed_masjid_phase2.py')
    if os.path.exists(path):
        print('Running seed_masjid_phase2.py ...')
        # Inherit env (expects GOOGLE_APPLICATION_CREDENTIALS)
        subprocess.check_call([sys.executable, path])
    else:
        print('seed_masjid_phase2.py not found; skipping Phase 2 seed.')


def maybe_seed_events():
    path = os.path.join('scripts', 'seed_events_announcements.py')
    if os.path.exists(path):
        print('Running seed_events_announcements.py ...')
        subprocess.check_call([sys.executable, path, '--link-to-first-initiative'])
    else:
        print('seed_events_announcements.py not found; skipping events seed.')


def maybe_seed_demo_donations():
    path = os.path.join('scripts', 'seed_demo_donations.py')
    if os.path.exists(path):
        print('Running seed_demo_donations.py ...')
        subprocess.check_call([sys.executable, path, '--clean'])
    else:
        print('seed_demo_donations.py not found; skipping Demo Donations seed.')


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('--no-backup', action='store_true')
    parser.add_argument('--skip-auth-sync', action='store_true')
    parser.add_argument('--seed-events', action='store_true')
    parser.add_argument('--seed-phase2', action='store_true')
    parser.add_argument('--seed-demo-donations', action='store_true')
    args = parser.parse_args(argv)

    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred)
    db = firestore.Client()
    print('Firebase initialized.')

    if not args.no_backup:
        for col in COLLECTIONS:
            print(f'Backing up {col} ...')
            backup_collection(db, col)

    for col in COLLECTIONS:
        print(f'Deleting {col} ...')
        delete_collection(db, col)

    print('Seeding permissions ...')
    seed_permissions(db)
    print('Seeding roles ...')
    seed_roles(db)

    if not args.skip_auth_sync:
        print('Syncing Auth users ...')
        sync_auth_users_to_firestore(db)

    if args.seed_phase2:
        maybe_run_seed_phase2()

    if args.seed_events:
        maybe_seed_events()

    if args.seed_demo_donations:
        maybe_seed_demo_donations()

    print('Reset + seed complete.')


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]) or 0)
