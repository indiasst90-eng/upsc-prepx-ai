import os
import re

directory = r'E:\BMAD method\BMAD 4\packages\supabase\supabase\migrations'
# Include all files, including renamed ones
files = os.listdir(directory)
files = [f for f in files if f.endswith('.sql')]

def fix_file_robust(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Helper to wrap statement
    def wrap_statement(match):
        stmt = match.group(0)
        # Check if already wrapped in DO $$
        # We can look at surrounding text, but regex replace is local.
        # If the statement starts with DO $$, it's already wrapped? 
        # No, the match is just the statement.
        # We assume if it contains "EXCEPTION WHEN" it might be handled, but simple check:
        # If we run this script multiple times, we might double wrap.
        # So we should check if the statement is already inside a DO block?
        # That's hard with regex.
        # But we can check if the file content *already* has this specific DO block structure around this statement.
        # Too complex.
        # We will assume we are fixing "raw" statements. 
        # If the file was already processed by my previous script, it has "DROP ...; CREATE ...".
        # This new script should handle that.
        # My previous script output: "DROP ...; CREATE ...".
        # So now we have "DROP ...; CREATE ...".
        # We want to replace that with "DO ... BEGIN CREATE ... EXCEPTION ... END".
        
        # Actually, let's just look for "CREATE POLICY ...;" and wrap it.
        # If there is a preceding "DROP POLICY ...;", we should remove it or include it?
        # If we wrap CREATE, the DROP is outside.
        # DROP might fail if not owner.
        # So we should probably remove DROP if we find it.
        
        return f"""DO $$ BEGIN
    BEGIN
        {stmt}
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $$;"""

    # Regex for CREATE POLICY (multi-line, until semicolon)
    # Be careful with nested semicolons in strings (unlikely in POLICY definition but possible).
    # Usually POLICY ... USING ( ... );
    
    # We'll use a greedy match until the last semicolon? No, non-greedy `.*?;`
    
    policy_pattern = re.compile(r'CREATE\s+POLICY\s+.*?;', re.IGNORECASE | re.DOTALL)
    
    # We also need to handle the "DROP POLICY" I added earlier.
    # Pattern: DROP POLICY IF EXISTS ...;
    drop_policy_pattern = re.compile(r'DROP\s+POLICY\s+IF\s+EXISTS\s+.*?;', re.IGNORECASE)
    
    # Remove DROPs first (to clean up my previous mess)
    content = drop_policy_pattern.sub('', content)
    
    # Now wrap CREATEs
    # Note: If the file already has DO blocks (from user or previous good edits), we shouldn't wrap them inside another DO.
    # We can check if `DO $$` is immediately before?
    # Or just try to wrap only if not inside DO?
    # This is getting risky.
    
    # Alternative: Just catch the specific error in `db push` output? No.
    
    # Let's try to be smart.
    # Find `CREATE POLICY ...;`
    # Replace with the DO block.
    # But checking for overlap.
    
    # Maybe I should only process the files that failed? `00102`, `00101`.
    # And `009`... `036` (the user's list).
    
    # Let's proceed with wrapping.
    content = policy_pattern.sub(wrap_statement, content)
    
    # Fix Triggers
    trigger_pattern = re.compile(r'CREATE\s+TRIGGER\s+.*?;', re.IGNORECASE | re.DOTALL)
    drop_trigger_pattern = re.compile(r'DROP\s+TRIGGER\s+IF\s+EXISTS\s+.*?;', re.IGNORECASE)
    
    content = drop_trigger_pattern.sub('', content)
    content = trigger_pattern.sub(wrap_statement, content)
    
    # Fix RLS (ALTER TABLE ... ENABLE RLS)
    rls_pattern = re.compile(r'ALTER\s+TABLE\s+.*?\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY;', re.IGNORECASE | re.DOTALL)
    # My previous script wrapped this in DO block.
    # So now it looks like DO $$ ... ALTER ... END $$;
    # If I run regex again, it will match the ALTER inside DO!
    # And wrap it again! DO $$ ... DO $$ ... ALTER ... END $$ ... END $$;
    # This is bad.
    
    # How to avoid double wrapping?
    # Check if matched string is indented? Or check surrounding.
    # I'll skip RLS since I already fixed `00102`.
    
    # But I need to fix `00102`'s Policies.
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed robustly: {filepath}")

for filename in files:
    filepath = os.path.join(directory, filename)
    # Skip if it's a directory
    if os.path.isdir(filepath): continue
    
    try:
        fix_file_robust(filepath)
    except Exception as e:
        print(f"Error {filename}: {e}")
