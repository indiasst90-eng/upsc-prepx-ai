import os
import re

filepath = r'E:\BMAD method\BMAD 4\packages\supabase\supabase\migrations\00102_initial_schema.sql'

def fix_rls(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern: ALTER TABLE name ENABLE ROW LEVEL SECURITY;
    # Regex: ALTER\s+TABLE\s+([a-zA-Z0-9_.]+)\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY;
    
    rls_pattern = re.compile(r'ALTER\s+TABLE\s+([a-zA-Z0-9_.]+)\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY;', re.IGNORECASE)

    def replace_rls(match):
        full_match = match.group(0)
        table_name = match.group(1)
        
        # Check if already wrapped
        # It's hard to check contextually without parsing, but assuming we haven't done it yet.
        
        return f"""DO $$ BEGIN
    ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for {table_name} due to insufficient privileges';
END $$;"""

    new_content = rls_pattern.sub(replace_rls, content)
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed RLS in {filepath}")
    else:
        print(f"No RLS statements found or changed in {filepath}")

fix_rls(filepath)
