"""
Script: seed_masjid_phase2.py

Seeds a real initiative and related campaigns/tasks:
- Initiative: "Masjid Project Phase 2 — Construction"
- Campaigns: online (e.g., Social Media, Email) and offline (e.g., Special Gathering, Public Event)
- Tasks: a few linked to campaigns and one independent

Usage:
  python scripts/seed_masjid_phase2.py

Requirements:
- google-cloud-firestore
- Service account key JSON (set GOOGLE_APPLICATION_CREDENTIALS env variable)
"""

from google.cloud import firestore
from google.cloud.firestore_v1 import FieldFilter
from google.api_core.exceptions import GoogleAPIError
from datetime import datetime, timedelta, timezone


SEED_TAG = 'masjid_phase2_v1'


def ensure_initiative(db: firestore.Client):
    slug = 'masjid-project-phase-2-construction'
    q = db.collection('initiatives').where(filter=FieldFilter('slug', '==', slug)).limit(1).get()
    if q:
        print(f"Found existing initiative by slug '{slug}': {q[0].id}")
        doc = q[0]
        data = doc.to_dict()
        patch = {}
        if data.get('goalAmount') in (None, 0):
            patch['goalAmount'] = 20000000
        if data.get('publicVisible') is None:
            patch['publicVisible'] = True
        if data.get('featured') is None:
            patch['featured'] = True
        if not data.get('milestones'):
            patch['milestones'] = [
                {'title': 'Foundation complete', 'percent': 25},
                {'title': 'Structure up', 'percent': 50},
                {'title': 'Finishing', 'percent': 75},
            ]
        if data.get('location') in (None, ''):
            patch['location'] = 'Hyderabad'
        if patch:
            patch['updatedAt'] = firestore.SERVER_TIMESTAMP
            doc.reference.update(patch)
            print(f"Patched existing initiative: {list(patch.keys())}")
        return doc.reference

    initiative_data = {
        'title': 'Masjid Project Phase 2 — Construction',
        'description': 'Construction phase of the MISK Masjid project.',
        'owner': None,
        'participants': None,
        'publicVisible': True,
        'slug': slug,
        'featured': True,
        'coverImageUrl': '',
        'gallery': [],
        'tags': ['masjid', 'construction', 'phase2'],
        'location': 'Hyderabad',
        'goalAmount': 20000000,  # INR
        'raisedAmount': 0,
        'milestones': [
            {'title': 'Foundation complete', 'percent': 25},
            {'title': 'Structure up', 'percent': 50},
            {'title': 'Finishing', 'percent': 75},
        ],
        'startDate': firestore.SERVER_TIMESTAMP,
        'endDate': None,
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }
    # Create with explicit doc to avoid add() return shape differences across versions
    doc_ref = db.collection('initiatives').document()
    doc_ref.set(initiative_data)
    print(f"Created initiative: {doc_ref.id}")
    return doc_ref


def upsert_campaigns(db: firestore.Client, initiative_ref):
    campaigns = [
        {
            'name': 'Social Media Campaign - Phase 2',
            'description': 'Awareness and donations via social channels.',
            'category': 'online',
            'type': 'fundraising',
            'goalAmount': 1000000,  # ₹10 Lakh
            'status': 'active',
            'priority': 'high',
            'publicVisible': True,
            'featured': True,
            'estimatedCost': 500000,
            'actualCost': 0,
            'proposedBy': 'manager@miskewt.org',
        },
        {
            'name': 'Email/Newsletter Drive',
            'description': 'Periodic donor updates and appeals.',
            'category': 'online',
            'type': 'fundraising',
            'goalAmount': 500000,  # ₹5 Lakh
            'status': 'planned',
            'priority': 'medium',
            'publicVisible': True,
            'featured': False,
            'estimatedCost': 200000,
            'actualCost': 0,
            'proposedBy': 'manager@miskewt.org',
        },
        {
            'name': 'Special Gathering',
            'description': 'In-person fundraising event.',
            'category': 'offline',
            'type': 'event',
            'status': 'on_hold',
            'priority': 'medium',
            'publicVisible': False,
            'featured': False,
            'estimatedCost': 300000,
            'actualCost': 0,
            'proposedBy': 'manager@miskewt.org',
        },
        {
            'name': 'Public Event Outreach',
            'description': 'Booths and pamphlets during public events.',
            'category': 'offline',
            'type': 'outreach',
            'status': 'planned',
            'priority': 'low',
            'publicVisible': True,
            'featured': False,
            'estimatedCost': 400000,
            'actualCost': 0,
            'proposedBy': 'manager@miskewt.org',
        },
    ]

    refs = {}
    for c in campaigns:
        data = {
            'name': c['name'],
            'description': c.get('description'),
            'category': c['category'],
            'type': c.get('type'),
            'goalAmount': c.get('goalAmount'),
            'initiative': initiative_ref,
            'manager': None,
            'startDate': firestore.SERVER_TIMESTAMP,
            'endDate': None,
            'publicVisible': c.get('publicVisible', True),
            'featured': c.get('featured', False),
            'status': c.get('status', 'planned'),
            'priority': c.get('priority'),
            'estimatedCost': c.get('estimatedCost'),
            'actualCost': c.get('actualCost'),
            'proposedBy': c.get('proposedBy'),
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }

        existing = (
            db.collection('campaigns')
            .where(filter=FieldFilter('name', '==', c['name']))
            .where(filter=FieldFilter('initiative', '==', initiative_ref))
            .limit(1)
            .get()
        )
        if existing:
            ref = existing[0].reference
            ref.update({**data, 'updatedAt': firestore.SERVER_TIMESTAMP})
            print(f"Updated campaign: {c['name']} -> {ref.id}")
        else:
            ref = db.collection('campaigns').document()
            ref.set(data)
            print(f"Created campaign: {c['name']} -> {ref.id}")
        refs[c['name']] = ref

    return refs


def _delete_in_batches(qsnap_docs, db):
    count = 0
    batch = db.batch()
    for i, doc in enumerate(qsnap_docs, start=1):
        batch.delete(doc.reference)
        count += 1
        if i % 450 == 0:
            batch.commit()
            batch = db.batch()
    batch.commit()
    return count


def cleanup_seed_data(db: firestore.Client, initiative_ref, campaign_refs=None):
    deleted_total = 0
    # Primary: delete donations by seedTag
    don_seeded = (
        db.collection('donations')
        .where(filter=FieldFilter('seedTag', '==', SEED_TAG))
        .get()
    )
    deleted_total += _delete_in_batches(don_seeded, db)

    # Legacy donation cleanup by known txnIds
    known_txn_ids = ['UPI-001', 'CHQ-7788']
    for tx in known_txn_ids:
        legacy = (
            db.collection('donations')
            .where(filter=FieldFilter('txnId', '==', tx))
            .where(filter=FieldFilter('initiative', '==', initiative_ref))
            .get()
        )
        deleted_total += _delete_in_batches(legacy, db)

    # Legacy anonymous cash duplicate cleanup (no txnId)
    anon_leg = (
        db.collection('donations')
        .where(filter=FieldFilter('initiative', '==', initiative_ref))
        .where(filter=FieldFilter('amount', '==', 8000))
        .get()
    )
    anon_leg = [d for d in anon_leg if (d.get('method') == 'Cash' and (d.get('donor') or {}).get('email') == 'anon@example.com')]
    deleted_total += _delete_in_batches(anon_leg, db)

    # Primary: delete tasks by seedTag
    task_seeded = (
        db.collection('tasks')
        .where(filter=FieldFilter('seedTag', '==', SEED_TAG))
        .get()
    )
    deleted_total += _delete_in_batches(task_seeded, db)

    # Legacy task cleanup
    seeded_titles = [
        'Draft social media calendar',
        'Book venue for special gathering',
        'Create donor pledge form',
    ]
    # By title + initiative
    for title in seeded_titles:
        legacy_tasks = (
            db.collection('tasks')
            .where(filter=FieldFilter('title', '==', title))
            .where(filter=FieldFilter('initiative', '==', initiative_ref))
            .get()
        )
        deleted_total += _delete_in_batches(legacy_tasks, db)
        # By title only where initiative missing
        legacy_missing_initiative = (
            db.collection('tasks')
            .where(filter=FieldFilter('title', '==', title))
            .get()
        )
        legacy_missing_initiative = [d for d in legacy_missing_initiative if 'initiative' not in d.to_dict()]
        deleted_total += _delete_in_batches(legacy_missing_initiative, db)

    # If we have campaign refs, also delete by title + campaign
    if campaign_refs:
        for camp_ref in campaign_refs.values():
            for title in seeded_titles:
                legacy_by_campaign = (
                    db.collection('tasks')
                    .where(filter=FieldFilter('title', '==', title))
                    .where(filter=FieldFilter('campaign', '==', camp_ref))
                    .get()
                )
                deleted_total += _delete_in_batches(legacy_by_campaign, db)

    print(f"Cleanup complete. Deleted {deleted_total} old seeded/legacy docs.")


def seed_donations(db: firestore.Client, initiative_ref, campaign_refs):
    now = datetime.now(timezone.utc)
    donations = [
        {
            'seedKey': 'phase2-d1',
            'amount': 250000,  # ₹2.5 Lakh
            'currency': 'INR',
            'status': 'confirmed',
            'bankReconciled': True,
            'reconciledAt': now,
            'initiative': initiative_ref,
            'campaign': campaign_refs.get('Social Media Campaign - Phase 2'),
            'donor': {'name': 'Azeez Ahmed', 'phone': '9xxxxxxxxx', 'email': 'azeez@example.com', 'pan': 'ABCDE1234F'},
            'method': 'UPI',
            'txnId': 'UPI-001',
            'source': 'erp',
            'receivedAt': now,
        },
        {
            'seedKey': 'phase2-d2',
            'amount': 12000,
            'currency': 'INR',
            'status': 'confirmed',
            'bankReconciled': False,
            'initiative': initiative_ref,
            'campaign': campaign_refs.get('Email/Newsletter Drive'),
            'donor': {'name': 'Khan', 'phone': '9xxxxxxxx1', 'email': 'khan@example.com', 'pan': 'ABCDE1234G'},
            'method': 'Cheque',
            'txnId': 'CHQ-7788',
            'source': 'erp',
            'receivedAt': now,
        },
        {
            'seedKey': 'phase2-d3',
            'amount': 8000,
            'currency': 'INR',
            'status': 'confirmed',
            'bankReconciled': True,
            'initiative': initiative_ref,
            'campaign': None,
            'donor': {'name': 'Anonymous', 'phone': '9xxxxxxxx2', 'email': 'anon@example.com'},
            'method': 'Cash',
            'txnId': None,
            'source': 'erp',
            'receivedAt': now,
        },
    ]

    confirmed_sum = 0
    reconciled_sum = 0

    for d in donations:
        data = {
            'seedTag': SEED_TAG,
            'seedKey': d['seedKey'],
            'amount': d['amount'],
            'currency': d.get('currency', 'INR'),
            'status': d.get('status', 'pending'),
            'bankReconciled': d.get('bankReconciled', False),
            'bankRef': d.get('bankRef'),
            'reconciledAt': d.get('reconciledAt'),
            'initiative': initiative_ref,
            'campaign': d.get('campaign'),
            'donor': d.get('donor'),
            'method': d.get('method', 'Other'),
            'txnId': d.get('txnId'),
            'source': d.get('source', 'erp'),
            'receiptNo': d.get('receiptNo'),
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
            'receivedAt': d.get('receivedAt'),
        }
        # Upsert by seedKey
        existing = (
            db.collection('donations')
            .where(filter=FieldFilter('seedKey', '==', d['seedKey']))
            .limit(1)
            .get()
        )
        if existing:
            ref = existing[0].reference
            ref.set(data, merge=True)
        else:
            ref = db.collection('donations').document()
            ref.set(data)
        if d.get('status') == 'confirmed':
            confirmed_sum += d['amount']
            if d.get('bankReconciled'):
                reconciled_sum += d['amount']

    print('Seeded donations (confirmed + reconciled mix, idempotent).')

    db.document(initiative_ref.path).update({
        'computedRaisedAmount': confirmed_sum,
        'reconciledRaisedAmount': reconciled_sum,
        'lastComputedAt': firestore.SERVER_TIMESTAMP,
    })
    print('Updated initiative roll-up fields for testing.')


def seed_tasks(db: firestore.Client, initiative_ref):
    # Fetch needed campaign refs by name for linking
    names = [
        'Social Media Campaign - Phase 2',
        'Special Gathering',
    ]
    refs = {}
    for n in names:
        q = (
            db.collection('campaigns')
            .where(filter=FieldFilter('name', '==', n))
            .where(filter=FieldFilter('initiative', '==', initiative_ref))
            .limit(1)
            .get()
        )
        refs[n] = q[0].reference if q else None

    now = datetime.now(timezone.utc)
    tasks = [
        {
            'seedKey': 'phase2-t1',
            'title': 'Draft social media calendar',
            'description': 'Content plan for next 4 weeks (FB/IG/Twitter).',
            'dueDate': now + timedelta(days=7),
            'status': 'pending',
            'campaign_ref': refs.get('Social Media Campaign - Phase 2'),
        },
        {
            'seedKey': 'phase2-t2',
            'title': 'Book venue for special gathering',
            'description': 'Coordinate with partners and lock date.',
            'dueDate': now + timedelta(days=14),
            'status': 'pending',
            'campaign_ref': refs.get('Special Gathering'),
        },
        {
            'seedKey': 'phase2-t3',
            'title': 'Create donor pledge form',
            'description': 'Online + printable versions.',
            'dueDate': now + timedelta(days=10),
            'status': 'pending',
            'campaign_ref': None,  # independent task
        },
    ]

    for t in tasks:
        data = {
            'seedTag': SEED_TAG,
            'seedKey': t['seedKey'],
            'title': t['title'],
            'description': t.get('description'),
            'status': t.get('status', 'pending'),
            'assignedTo': None,
            'workflow': None,
            'dueDate': t['dueDate'],
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }
        if t['campaign_ref'] is not None:
            data['campaign'] = t['campaign_ref']
            data['initiative'] = initiative_ref
        else:
            data['initiative'] = initiative_ref

        # Upsert by seedKey
        existing = (
            db.collection('tasks')
            .where(filter=FieldFilter('seedKey', '==', t['seedKey']))
            .limit(1)
            .get()
        )
        if existing:
            ref = existing[0].reference
            ref.set(data, merge=True)
            print(f"Updated task: {t['title']} -> {ref.id}")
        else:
            doc = db.collection('tasks').document()
            doc.set(data)
            print(f"Created task: {t['title']} -> {doc.id}")


def main():
    try:
        db = firestore.Client()
        print("Connected to Firestore. Seeding Masjid Phase 2...")

        initiative_ref = ensure_initiative(db)

        # Upsert campaigns first so we can match legacy tasks by campaign
        campaign_refs = upsert_campaigns(db, initiative_ref)

        # Clean duplicates (donations/tasks) using initiative and campaign refs
        cleanup_seed_data(db, initiative_ref, campaign_refs)

        # Re-seed unique tasks and donations
        seed_tasks(db, initiative_ref)
        seed_donations(db, initiative_ref, campaign_refs)

        print("Seeding complete.")
    except GoogleAPIError as e:
        print(f"Firestore error: {e}")
    except Exception as ex:
        print(f"Error: {ex}")


if __name__ == "__main__":
    main()
