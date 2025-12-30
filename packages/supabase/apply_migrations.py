import psycopg2
import os
import sys

# Configuration
HOST = "89.117.60.144"
PORT = 5432
USER = "postgres"
PASSWORD = "postgres"
DBNAME = "postgres"
MIGRATIONS_DIR = "supabase/migrations"

# Range of files to apply
START_PREFIX = "009"
END_PREFIX = "036"

def get_migration_files():
    files = []
    try:
        all_files = os.listdir(MIGRATIONS_DIR)
        for f in all_files:
            if f.endswith(".sql"):
                prefix = f.split('_')[0]
                if prefix.isdigit():
                    if START_PREFIX <= prefix <= END_PREFIX:
                        files.append(os.path.join(MIGRATIONS_DIR, f))
    except Exception as e:
        print(f"Error listing files: {e}")
        sys.exit(1)
    
    files.sort()
    return files

def apply_migration(conn, filepath):
    filename = os.path.basename(filepath)
    print(f"Applying {filename}...")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        sql = f.read()

    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
        print(f"SUCCESS: {filename}")
        return True
    except Exception as e:
        conn.rollback()
        print(f"FAILED: {filename}")
        print(f"Error: {e}")
        return False

def main():
    try:
        conn = psycopg2.connect(
            host=HOST,
            port=PORT,
            user=USER,
            password=PASSWORD,
            dbname=DBNAME,
            sslmode='disable'
        )
        print("Connected to database.")
    except Exception as e:
        print(f"Connection failed: {e}")
        sys.exit(1)

    files = get_migration_files()
    print(f"Found {len(files)} files to migrate.")

    failed = []
    for f in files:
        if not apply_migration(conn, f):
            failed.append(os.path.basename(f))
            # We continue? Or stop? 
            # If we want to fix errors, we should probably stop and report.
            # But the user wants "all have been migrated?", so let's try to apply as many as possible
            # or stop at the first blocker. 
            # Usually dependencies require sequential order.
            print("Stopping due to error.")
            break
            
    conn.close()
    
    if failed:
        print(f"\nMigration stopped. Failed at: {failed[0]}")
        sys.exit(1)
    else:
        print("\nAll migrations applied successfully!")

if __name__ == "__main__":
    main()
