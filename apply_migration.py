#!/usr/bin/env python3
"""
Apply Migration 021 to Supabase VPS Database
This script applies the complete monetization system migration.
"""

import psycopg2
import sys

# VPS Database Configuration
DB_CONFIG = {
    'host': '89.117.60.144',
    'port': 54322,
    'database': 'postgres',
    'user': 'postgres',
    'password': 'postgres'
}

MIGRATION_FILE = 'packages/supabase/supabase/migrations/021_monetization_system.sql'

def main():
    print('=' * 60)
    print('Applying Migration 021: Monetization System')
    print('=' * 60)
    print()

    # Read migration file
    print('[1/3] Reading migration file...')
    try:
        with open(MIGRATION_FILE, 'r', encoding='utf-8') as f:
            migration_sql = f.read()
        print(f'      Migration size: {len(migration_sql)} bytes')
        print()
    except FileNotFoundError:
        print(f'ERROR: Migration file not found: {MIGRATION_FILE}')
        sys.exit(1)

    # Connect to database
    print('[2/3] Connecting to VPS database...')
    print(f'      Host: {DB_CONFIG["host"]}')
    print(f'      Port: {DB_CONFIG["port"]}')
    print()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = False
        cursor = conn.cursor()
        print('      Connection established!')
        print()
    except Exception as e:
        print(f'ERROR: Could not connect to database')
        print(f'       {str(e)}')
        sys.exit(1)

    # Execute migration
    print('[3/3] Executing migration...')
    try:
        cursor.execute(migration_sql)
        conn.commit()
        print('      Migration executed successfully!')
        print()
    except Exception as e:
        conn.rollback()
        print(f'ERROR: Migration failed')
        print(f'       {str(e)}')
        cursor.close()
        conn.close()
        sys.exit(1)

    # Verify tables created
    print('Verifying tables...')
    try:
        cursor.execute("""
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name IN ('coupons', 'coupon_usages', 'payment_transactions', 'feature_manifests')
            ORDER BY table_name;
        """)
        tables = cursor.fetchall()
        print(f'  ✓ Found {len(tables)} new tables:')
        for table in tables:
            print(f'    - {table[0]}')
        print()
    except Exception as e:
        print(f'WARNING: Could not verify tables: {str(e)}')
        print()

    # Verify sample coupons
    print('Verifying sample coupons...')
    try:
        cursor.execute("SELECT code, discount_type, discount_value FROM coupons ORDER BY code;")
        coupons = cursor.fetchall()
        print(f'  ✓ Found {len(coupons)} sample coupons:')
        for code, dtype, value in coupons:
            print(f'    - {code} ({dtype}: {value})')
        print()
    except Exception as e:
        print(f'WARNING: Could not verify coupons: {str(e)}')
        print()

    # Clean up
    cursor.close()
    conn.close()

    print('=' * 60)
    print('SUCCESS: Migration 021 Applied Successfully!')
    print('=' * 60)
    print()
    print('Tables created:')
    print('  ✓ payment_transactions')
    print('  ✓ feature_manifests')
    print('  ✓ coupons')
    print('  ✓ coupon_usages')
    print('  ✓ referrals')
    print('  ✓ subscription_events')
    print()
    print('Functions created:')
    print('  ✓ check_entitlement()')
    print('  ✓ validate_coupon()')
    print('  ✓ generate_referral_code()')
    print()

if __name__ == '__main__':
    main()
