import psycopg2
import os
import re

HOST = "89.117.60.144"
PORT = 5432
USER = "postgres"
PASSWORD = "postgres"
DBNAME = "postgres"
MIGRATIONS_DIR = "migrations" # relative to packages/supabase/

TARGET_FILES = [
    "034_pyq_system.sql",
    "035_pyq_videos.sql",
    "036_difficulty_tagging.sql",
    "037_pyq_bookmarks.sql",
    "038_practice_sessions.sql",
    "039_generated_questions.sql",
    "040_mcq_distractors.sql",
    "041_difficulty_adaptive_complete.sql",
    "042_practice_session_complete.sql",
    "043_question_bank_analytics.sql",
    "044_assistant_conversations.sql",
    "045_assistant_preferences.sql",
    "046_assistant_checkins.sql",
    "047_mindmaps.sql",
    "048_mindmap_collaboration.sql",
    "049_bookmarks.sql",
    "050_bookmark_links.sql",
    "051_spaced_repetition.sql",
    "052_bookmark_collections.sql",
    "053_documentary_scripts.sql",
    "054_documentary_rendering.sql",
    "055_weekly_documentary.sql",
    "056_documentary_library.sql",
    "057_math_solver.sql",
    "058_memory_palace.sql",
    "059_interactive_maps.sql",
    "060_ethics_roleplay.sql",
    "061_ethics_simulator.sql",
    "062_case_law_explainer.sql",
    "063_interview_studio.sql",
    "064_interview_debrief.sql",
    "065_gamification_xp_badges_streaks.sql",
    "066_topic_difficulty_predictor.sql",
    "067_immersive_360_experiences.sql",
    "068_voice_teacher_customization.sql",
    "069_social_media_publisher.sql",
    "070_search_history.sql",
    "071_admin_settings.sql"
]

def fix_sql_content(sql):
    lines = sql.split('\n')
    new_lines = []
    
    for line in lines:
        # Skip ownership changes
        if "OWNER TO" in line:
            new_lines.append(f"-- {line} -- Skipped owner change")
            continue
        new_lines.append(line)
        
    content = "\n".join(new_lines)
    
    # Use negative lookahead to check if IF NOT EXISTS is already there
    # Matches CREATE INDEX followed by whitespace, NOT followed by IF NOT EXISTS
    content = re.sub(r'CREATE INDEX\s+(?!IF NOT EXISTS)', 'CREATE INDEX IF NOT EXISTS ', content, flags=re.IGNORECASE)
    
    # Replace CREATE TRIGGER with CREATE OR REPLACE TRIGGER (Postgres 14+)
    content = re.sub(r'CREATE TRIGGER ', r'CREATE OR REPLACE TRIGGER ', content)
    
    # Define wrapper function
    def wrap_in_do(match):
        stmt = match.group(0)
        # Escape quotes in stmt if needed? No, we use $$ delimiter.
        return f"DO $migration$ BEGIN BEGIN {stmt} EXCEPTION WHEN OTHERS THEN NULL; END; END $migration$;"
        
    # Wrap DROP TRIGGER in DO block
    content = re.sub(r'DROP TRIGGER .*?;', wrap_in_do, content)
    
    # Wrap ALTER TABLE ... ENABLE ROW LEVEL SECURITY
    content = re.sub(r'ALTER TABLE .*? ENABLE ROW LEVEL SECURITY;', wrap_in_do, content)
    
    # Wrap CREATE POLICY
    content = re.sub(r'CREATE POLICY .*?;', wrap_in_do, content, flags=re.DOTALL)
    
    # Wrap DROP POLICY
    content = re.sub(r'DROP POLICY .*?;', wrap_in_do, content, flags=re.DOTALL)
    
    # Wrap COMMENT ON
    content = re.sub(r'COMMENT ON .*?;', wrap_in_do, content, flags=re.DOTALL)
    
    return content

def apply_migration(conn, filename, filepath):
    print(f"Processing {filename}...")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        raw_sql = f.read()
        
    sql = fix_sql_content(raw_sql)
    
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
        # Dump the failed SQL for debugging
        with open(f"failed_{filename}", "w", encoding='utf-8') as df:
            df.write(sql)
        print(f"Failed SQL written to failed_{filename}")
        return False

def main():
    conn = psycopg2.connect(
        host=HOST,
        port=PORT,
        user=USER,
        password=PASSWORD,
        dbname=DBNAME,
        sslmode='disable'
    )
    
    # Sort target files
    TARGET_FILES.sort()
    
    for filename in TARGET_FILES:
        filepath = os.path.join(MIGRATIONS_DIR, filename)
        if not os.path.exists(filepath):
            print(f"Warning: File not found: {filepath}")
            continue
            
        if not apply_migration(conn, filename, filepath):
            print("Stopping due to error.")
            break
            
    conn.close()

if __name__ == "__main__":
    main()
