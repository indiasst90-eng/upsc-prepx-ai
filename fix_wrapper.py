import os
import re

directory = r'E:\BMAD method\BMAD 4\packages\supabase\supabase\migrations'
files = os.listdir(directory)
files = [f for f in files if f.endswith('.sql')]

def fix_wrapper(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace the start of the wrapper
    # DO $$ BEGIN
    #     BEGIN
    content = content.replace("DO $$ BEGIN\n    BEGIN", "DO $migration$ BEGIN\n    BEGIN")
    
    # Replace the end of the wrapper
    #     END;
    # END $$;
    content = content.replace("    END;\nEND $$;", "    END;\nEND $migration$;")
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed wrapper in: {filepath}")

for filename in files:
    filepath = os.path.join(directory, filename)
    if os.path.isdir(filepath): continue
    try:
        fix_wrapper(filepath)
    except Exception as e:
        print(f"Error {filename}: {e}")
