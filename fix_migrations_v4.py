import os
import re

directory = r'E:\BMAD method\BMAD 4\packages\supabase\supabase\migrations'
files = os.listdir(directory)
files = [f for f in files if f.endswith('.sql')]

def fix_file_robust(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Helper to wrap statement
    def wrap_statement(match):
        stmt = match.group(0)
        start = match.start()
        # Check if already wrapped
        preceding = content[max(0, start-100):start]
        if re.search(r'BEGIN\s*$', preceding) or re.search(r'DO\s*\$\$\s*BEGIN\s*$', preceding) or re.search(r'DO\s*\$migration\$\s*BEGIN\s*$', preceding) or "BEGIN" in preceding[-20:]:
            return stmt
        
        # Use $migration$ delimiter to avoid conflict with $$ in functions
        return f"""DO $migration$ BEGIN
    BEGIN
        {stmt}
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;"""

    policy_pattern = re.compile(r'CREATE\s+POLICY\s+.*?;', re.IGNORECASE | re.DOTALL)
    trigger_pattern = re.compile(r'CREATE\s+TRIGGER\s+.*?;', re.IGNORECASE | re.DOTALL)
    index_pattern = re.compile(r'CREATE\s+(?:UNIQUE\s+)?INDEX\s+.*?;', re.IGNORECASE | re.DOTALL)
    rls_pattern = re.compile(r'ALTER\s+TABLE\s+.*?\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY;', re.IGNORECASE | re.DOTALL)
    function_pattern = re.compile(r'CREATE\s+OR\s+REPLACE\s+FUNCTION\s+.*?\$\$\s*LANGUAGE\s+\w+\s*;', re.IGNORECASE | re.DOTALL)
    
    # Remove existing DROPs (cleanup)
    content = re.sub(r'DROP\s+POLICY\s+IF\s+EXISTS\s+.*?;', '', content, flags=re.IGNORECASE)
    content = re.sub(r'DROP\s+TRIGGER\s+IF\s+EXISTS\s+.*?;', '', content, flags=re.IGNORECASE)
    
    def process_pattern(pat, text):
        def repl(m):
            s = m.group(0)
            start = m.start()
            preceding = text[max(0, start-100):start]
            if re.search(r'BEGIN\s*$', preceding) or re.search(r'DO\s*\$\$\s*BEGIN\s*$', preceding) or re.search(r'DO\s*\$migration\$\s*BEGIN\s*$', preceding) or "BEGIN" in preceding[-20:]:
                return s
            return f"""DO $migration$ BEGIN
    BEGIN
        {s}
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;"""
        return pat.sub(repl, text)

    content = process_pattern(policy_pattern, content)
    content = process_pattern(trigger_pattern, content)
    content = process_pattern(index_pattern, content)
    content = process_pattern(rls_pattern, content)
    content = process_pattern(function_pattern, content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed robustly: {filepath}")

for filename in files:
    filepath = os.path.join(directory, filename)
    if os.path.isdir(filepath): continue
    try:
        fix_file_robust(filepath)
    except Exception as e:
        print(f"Error {filename}: {e}")
