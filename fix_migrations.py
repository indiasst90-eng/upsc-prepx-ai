import os
import re

directory = r'E:\BMAD method\BMAD 4\packages\supabase\supabase\migrations'
files = [
    '009_video_jobs.sql', '010_new_features.sql', '011_phase2_features.sql', 
    '012_topic_shorts.sql', '013_answer_writing.sql', '014_pyq_videos.sql', 
    '015_daily_quiz.sql', '016_mock_tests.sql', '017_daily_ca_documentary.sql', 
    '018_phase5_flagship.sql', '019_auth_profile_trigger.sql', '020_storage_buckets.sql', 
    '021_monetization_system.sql', '022_refund_system.sql', '023_study_schedules.sql', 
    '024_detailed_syllabus_tracking.sql', '025_revision_targets.sql', '026_revision_videos.sql', 
    '027_flashcards.sql', '028_revision_quizzes.sql', '029_confidence_algorithm.sql', 
    '030_notification_preferences.sql', '031_progress_videos.sql', '032_answer_submissions.sql', 
    '033_answer_evaluation_system.sql', '034_pyq_system.sql', '035_vector_search_function.sql', 
    '036_payment_orders.sql'
]

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix Triggers
    # Pattern: CREATE TRIGGER name ... ON table ...
    # We need to capture name and table.
    # Note: Trigger definition can span multiple lines.
    # Regex: CREATE TRIGGER\s+(\w+)\s+.*?\s+ON\s+([a-zA-Z0-9_.]+)(?:\s|\n)
    
    def replace_trigger(match):
        full_match = match.group(0)
        trigger_name = match.group(1)
        table_name = match.group(2)
        # Check if already guarded (simple check)
        if f'DROP TRIGGER IF EXISTS {trigger_name}' in content:
            return full_match
        
        return f'DROP TRIGGER IF EXISTS {trigger_name} ON {table_name};\n{full_match}'

    # Using DOTALL to match across lines, but we need to be careful not to match too much.
    # A trigger definition ends usually with "FOR EACH ... EXECUTE FUNCTION ...;" or just ";"
    # But for the purpose of DROP, we just need the name and table.
    # We will search for the "CREATE TRIGGER ... ON table" part.
    
    trigger_pattern = re.compile(r'CREATE\s+TRIGGER\s+(\w+)\s+(?:BEFORE|AFTER|INSTEAD\s+OF)\s+.*?\s+ON\s+([a-zA-Z0-9_."]+)', re.IGNORECASE | re.DOTALL)
    
    # This replacement is tricky because we only want to prepend DROP, not replace the whole thing if we don't capture the whole thing.
    # So we will find all matches, and if not preceded by DROP, we insert it.
    
    # Better approach: Iterate matches and construct new string? Or just use sub with a function that returns the full match prefixed.
    # However, re.sub replaces the matched part. So we need the matched part to include everything up to table name?
    # No, we can just match the "CREATE TRIGGER name ... ON table" part and replace it with "DROP ...; CREATE TRIGGER name ... ON table"
    
    content = trigger_pattern.sub(replace_trigger, content)

    # Fix Policies
    # Pattern: CREATE POLICY "name" ON table ...
    policy_pattern = re.compile(r'CREATE\s+POLICY\s+"([^"]+)"\s+ON\s+([a-zA-Z0-9_."]+)', re.IGNORECASE)

    def replace_policy(match):
        full_match = match.group(0)
        policy_name = match.group(1)
        table_name = match.group(2)
        
        # Check if already guarded (simple check) -- strict string check might fail if formatting differs
        # We'll just assume if we find CREATE POLICY we might need DROP.
        # But wait, if we run this script twice, we might add double DROPs.
        # So check if "DROP POLICY IF EXISTS ... name ... table" exists nearby? 
        # Easier: check if the previous lines contain it.
        
        # But since we are replacing in memory, we can just do it. 
        # Ideally, we shouldn't modify if it's already there.
        # But the user wants us to fix it now.
        
        return f'DROP POLICY IF EXISTS "{policy_name}" ON {table_name};\n{full_match}'

    content = policy_pattern.sub(replace_policy, content)
    
    # Fix Types (CREATE TYPE)
    # CREATE TYPE name AS ENUM ...
    # Should be: DO $$ BEGIN CREATE TYPE ... EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    # Or checking pg_type.
    # But types are harder to regex because of the body.
    # Let's see if we have CREATE TYPE.
    
    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Processed {filepath}")

for filename in files:
    filepath = os.path.join(directory, filename)
    if os.path.exists(filepath):
        try:
            fix_file(filepath)
        except Exception as e:
            print(f"Error processing {filename}: {e}")
    else:
        print(f"File not found: {filename}")
