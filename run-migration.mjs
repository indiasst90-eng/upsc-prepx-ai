#!/usr/bin/env node
/**
 * Migration Runner for apply-migration-023.mjs
 * This script handles dependency issues and runs the migration safely
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

async function runMigration() {
    try {
        console.log('🚀 Starting migration execution...');
        
        // Check if dependencies are installed
        try {
            const { createClient } = await import('@supabase/supabase-js');
            console.log('✅ @supabase/supabase-js is available');
        } catch (error) {
            console.log('⚠️ @supabase/supabase-js not found, installing...');
            
            // Try to install dependencies
            const { execSync } = await import('child_process');
            try {
                execSync('npm install @supabase/supabase-js', { stdio: 'inherit' });
                console.log('✅ Dependencies installed');
            } catch (installError) {
                console.error('❌ Failed to install dependencies:', installError.message);
                console.log('Please run: npm install @supabase/supabase-js');
                process.exit(1);
            }
        }
        
        // Import and run the actual migration
        console.log('📁 Loading migration file...');
        const migrationModule = await import('./apply-migration-023.mjs');
        
        if (migrationModule.default) {
            console.log('🔄 Executing migration...');
            await migrationModule.default();
            console.log('✅ Migration completed successfully!');
        } else {
            console.log('❌ No default export found in migration file');
            process.exit(1);
        }
        
    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        process.exit(1);
    }
}

// Run the migration
runMigration();
