import os
import re

directory = r'E:\BMAD method\BMAD 4\packages\supabase\supabase\migrations'
files = os.listdir(directory)
files = [f for f in files if f.endswith('.sql')]

def restore_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Regex to find the wrapper and extract content
    # The wrapper adds indentation (maybe not, depends on f-string).
    # My script used:
    # return f"""DO $migration$ BEGIN
    #     BEGIN
    #         {stmt}
    #     EXCEPTION
    #         WHEN duplicate_object THEN NULL;
    #         WHEN insufficient_privilege THEN NULL;
    #     END;
    # END $migration$;"""
    
    # So we look for:
    # DO $migration$ BEGIN
    #     BEGIN
    #         (CONTENT)
    #     EXCEPTION
    #         WHEN duplicate_object THEN NULL;
    #         WHEN insufficient_privilege THEN NULL;
    #     END;
    # END $migration$;
    
    # We need to be careful with indentation/newlines.
    # The regex should be flexible with whitespace.
    
    pattern = re.compile(
        r'DO\s+\$migration\$\s+BEGIN\s+BEGIN\s+(.*?)\s+EXCEPTION\s+WHEN\s+duplicate_object\s+THEN\s+NULL;\s+WHEN\s+insufficient_privilege\s+THEN\s+NULL;\s+END;\s+END\s+\$migration\$;',
        re.DOTALL | re.IGNORECASE
    )
    
    def repl(match):
        return match.group(1)
    
    new_content = pattern.sub(repl, content)
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Restored: {filepath}")
    else:
        print(f"No wrapper found in: {filepath}")

for filename in files:
    filepath = os.path.join(directory, filename)
    if os.path.isdir(filepath): continue
    try:
        restore_file(filepath)
    except Exception as e:
        print(f"Error {filename}: {e}")
