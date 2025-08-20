import firebase_admin
from firebase_admin import credentials, firestore
import datetime
import json

# Initialize Firebase Admin
cred = credentials.Certificate('../misk-edu-and-welfare-trust-45c246941758.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

def seed_test_users():
    users_data = [
        {
            'name': 'Super Admin',
            'email': 'admin@miskewt.org',
            'isSuperAdmin': True,
            'designation': 'System Administrator',
            'status': 'active',
            'createdAt': firestore.SERVER_TIMESTAMP
        },
        {
            'name': 'Test Manager',
            'email': 'manager@miskewt.org',
            'isSuperAdmin': False,
            'designation': 'Program Manager',
            'status': 'active',
            'createdAt': firestore.SERVER_TIMESTAMP
        },
        # Add more test users as needed
    ]

    for user in users_data:
        db.collection('users').add(user)

def seed_test_initiatives():
    initiatives_data = [
        {
            'name': 'Education Program 2025',
            'description': 'Annual education support program',
            'status': 'active',
            'target': 100000,
            'achieved': 25000,
            'startDate': datetime.datetime.now(),
            'endDate': datetime.datetime.now() + datetime.timedelta(days=90),
            'createdAt': firestore.SERVER_TIMESTAMP
        },
        # Add more test initiatives
    ]

    for initiative in initiatives_data:
        db.collection('initiatives').add(initiative)

def seed_test_campaigns():
    campaigns_data = [
        {
            'name': 'Back to School 2025',
            'description': 'School supplies distribution',
            'status': 'planning',
            'target': 50000,
            'achieved': 0,
            'startDate': datetime.datetime.now() + datetime.timedelta(days=30),
            'endDate': datetime.datetime.now() + datetime.timedelta(days=60),
            'createdAt': firestore.SERVER_TIMESTAMP
        },
        # Add more test campaigns
    ]

    for campaign in campaigns_data:
        db.collection('campaigns').add(campaign)

def main():
    print("🚀 Starting test data seeding...")

    # Seed all collections
    seed_test_users()
    seed_test_initiatives()
    seed_test_campaigns()

    print("✅ Test data seeding complete!")

if __name__ == "__main__":
    main()
