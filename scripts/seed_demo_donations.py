"""
Seed a demo donations dataset for a "Demo Donations" scenario.

- Ensures a Demo initiative (by slug) exists or creates it
- Ensures a Demo campaign exists and links to the initiative
- Upserts a few sample donations by seedKey to avoid duplicates
- Optional cleanup by seedTag before reseeding

Usage:
  python scripts/seed_demo_donations.py [--clean]

Prereqs:
  - Set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account JSON
  - pip install -r scripts/requirements.txt
"""
from google.cloud import firestore
from google.cloud.firestore_v1 import FieldFilter
from datetime import datetime, timezone
import argparse

SEED_TAG = 'demo_donations_v1'
INITIATIVE_SLUG = 'demo-donations-initiative'
INITIATIVE_TITLE = 'Demo Donations — Showcase'
CAMPAIGN_NAME = 'Demo Donations Campaign'


def ensure_initiative(db: firestore.Client):
    q = db.collection('initiatives').where(filter=FieldFilter('slug', '==', INITIATIVE_SLUG)).limit(1).get()
    if q:
        ref = q[0].reference
        data = q[0].to_dict()
        patch = {}
        if data.get('publicVisible') is None:
            patch['publicVisible'] = True
        if data.get('featured') is None:
            patch['featured'] = True
        if data.get('goalAmount') in (None, 0):
            patch['goalAmount'] = 500000  # INR
        if patch:
            patch['updatedAt'] = firestore.SERVER_TIMESTAMP
            ref.update(patch)
        print(f"Using initiative: {ref.id}")
        return ref
    data = {
        'title': INITIATIVE_TITLE,
        'description': 'Demo dataset for donations showcase',
        'owner': None,
        'participants': None,
        'publicVisible': True,
        'slug': INITIATIVE_SLUG,
        'featured': True,
        'coverImageUrl': '',
        'gallery': [],
        'tags': ['demo', 'donations'],
        'location': 'Hyderabad',
        'goalAmount': 500000,
        'raisedAmount': 0,
        'milestones': [],
        'startDate': firestore.SERVER_TIMESTAMP,
        'endDate': None,
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }
    ref = db.collection('initiatives').document()
    ref.set(data)
    print(f"Created initiative: {ref.id}")
    return ref


def ensure_campaign(db: firestore.Client, initiative_ref):
    q = (
        db.collection('campaigns')
        .where(filter=FieldFilter('name', '==', CAMPAIGN_NAME))
        .where(filter=FieldFilter('initiative', '==', initiative_ref))
        .limit(1)
        .get()
    )
    data = {
        'name': CAMPAIGN_NAME,
        'description': 'Demo donations under the Demo initiative',
        'category': 'online',
        'type': 'fundraising',
        'goalAmount': 100000,
        'initiative': initiative_ref,
        'manager': None,
        'startDate': firestore.SERVER_TIMESTAMP,
        'endDate': None,
        'publicVisible': True,
        'featured': True,
        'status': 'active',
        'priority': 'medium',
        'estimatedCost': 0,
        'actualCost': 0,
        'proposedBy': 'demo@miskewt.org',
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }
    if q:
        ref = q[0].reference
        ref.update({**data, 'updatedAt': firestore.SERVER_TIMESTAMP})
        print(f"Using campaign (updated): {ref.id}")
        return ref
    ref = db.collection('campaigns').document()
    ref.set(data)
    print(f"Created campaign: {ref.id}")
    return ref


def cleanup_seed(db: firestore.Client, initiative_ref):
    # Delete donations by seedTag for a clean reseed
    qs = db.collection('donations').where(filter=FieldFilter('seedTag', '==', SEED_TAG)).get()
    batch = db.batch()
    count = 0
    for i, d in enumerate(qs, start=1):
        batch.delete(d.reference)
        count += 1
        if i % 450 == 0:
            batch.commit()
            batch = db.batch()
    batch.commit()
    print(f"Cleaned up {count} demo donations by seedTag.")


def upsert_donations(db: firestore.Client, initiative_ref, campaign_ref):
    now = datetime.now(timezone.utc)
    rows = [
        {
            'seedKey': 'demo-p1',
            'amount': 1500,
            'currency': 'INR',
            'status': 'confirmed',
            'bankReconciled': True,
            'donor': {'name': 'Demo User 1', 'email': 'demo1@example.com'},
            'method': 'UPI',
            'txnId': 'UPI-DEMO-1',
            'receivedAt': now,
        },
        {
            'seedKey': 'demo-p2',
            'amount': 7500,
            'currency': 'INR',
            'status': 'pending',
            'bankReconciled': False,
            'donor': {'name': 'Demo User 2', 'email': 'demo2@example.com'},
            'method': 'Bank Transfer',
            'txnId': 'NEFT-DEMO-2',
            'receivedAt': now,
        },
        {
            'seedKey': 'demo-p3',
            'amount': 25000,
            'currency': 'INR',
            'status': 'confirmed',
            'bankReconciled': False,
            'donor': {'name': 'Demo User 3', 'email': 'demo3@example.com'},
            'method': 'Cheque',
            'txnId': 'CHQ-DEMO-3',
            'receivedAt': now,
        },
    ]

    for r in rows:
        base = {
            'seedTag': SEED_TAG,
            'seedKey': r['seedKey'],
            'amount': r['amount'],
            'currency': r['currency'],
            'status': r['status'],
            'bankReconciled': r['bankReconciled'],
            'initiative': initiative_ref,
            'campaign': campaign_ref,
            'donor': r['donor'],
            'method': r['method'],
            'txnId': r['txnId'],
            'source': 'erp',
            'receivedAt': r['receivedAt'],
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }
        ex = db.collection('donations').where(filter=FieldFilter('seedKey', '==', r['seedKey'])).limit(1).get()
        if ex:
            ex[0].reference.set(base, merge=True)
            print(f"Updated donation {r['seedKey']}")
        else:
            db.collection('donations').document().set(base)
            print(f"Created donation {r['seedKey']}")

    print('Demo donations upserted (idempotent).')


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument('--clean', action='store_true', help='Delete previous demo donations by seedTag before seeding')
    args = parser.parse_args(argv)

    db = firestore.Client()
    print('Connected to Firestore. Seeding Demo Donations...')

    initiative_ref = ensure_initiative(db)
    campaign_ref = ensure_campaign(db, initiative_ref)

    if args.clean:
        cleanup_seed(db, initiative_ref)

    upsert_donations(db, initiative_ref, campaign_ref)

    print('Done.')


if __name__ == '__main__':
    import sys
    sys.exit(main(sys.argv[1:]) or 0)
