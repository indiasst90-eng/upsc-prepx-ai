/**
 * Standalone Migration Runner
 * This script runs apply-migration-023.mjs without external dependencies
 */

const { execSync } = require('child_process');
const fs = require('fs');

async function runMigration() {
    console.log('🚀 Starting direct migration execution...');
    
    try {
        // Check if migration file exists
        if (!fs.existsSync('./apply-migration-023.mjs')) {
            throw new Error('Migration file apply-migration-023.mjs not found');
        }
        
        console.log('📁 Migration file found');
        
        // Try to install dependencies first
        try {
            console.log('📦 Installing @supabase/supabase-js...');
            execSync('npm install @supabase/supabase-js --legacy-peer-deps', { 
                stdio: 'inherit' 
            });
        } catch (error) {
            console.log('⚠️ npm install failed, trying alternative approach...');
        }
        
        // Try different ways to run the migration
        const attempts = [
            () => this.runWithNode(),
            () => this.runWithNpx(),
            () => this.runWithLocalNode()
        ];
        
        for (const attempt of attempts) {
            try {
                await attempt();
                console.log('✅ Migration completed successfully!');
                return true;
            } catch (error) {
                console.log('❌ Attempt failed:', error.message);
                continue;
            }
        }
        
        throw new Error('All migration attempts failed');
        
    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        
        // Fallback: Use our automated migration system
        console.log('🔄 Falling back to automated migration system...');
        await this.runWithAutomatedSystem();
        
        return false;
    }
}

async function runWithNode() {
    console.log('🔄 Attempting direct node execution...');
    execSync('node apply-migration-023.mjs', { stdio: 'inherit' });
    return true;
}

async function runWithNpx() {
    console.log('🔄 Attempting npx execution...');
    execSync('npx node apply-migration-023.mjs', { stdio: 'inherit' });
    return true;
}

async function runWithLocalNode() {
    console.log('🔄 Attempting with local node_modules...');
    execSync('./node_modules/.bin/node apply-migration-023.mjs', { stdio: 'inherit' });
    return true;
}

async function runWithAutomatedSystem() {
    console.log('🤖 Using automated migration system...');
    
    // Copy migration file to our system
    const { copyFileSync } = require('fs');
    const migrationSource = './apply-migration-023.mjs';
    const migrationDest = '../Dr Varuni/Desktop/migrated_file.mjs';
    
    try {
        copyFileSync(migrationSource, migrationDest);
        console.log('📁 Migration file copied to automated system');
        
        // Run with our automated system
        execSync('node ../Dr Varuni/Desktop/simple_migration_automation.js migrated_file.mjs', { 
            stdio: 'inherit' 
        });
        
        return true;
    } catch (error) {
        console.error('❌ Automated system also failed:', error.message);
        return false;
    }
}

// Execute the migration
runMigration().then(success => {
    process.exit(success ? 0 : 1);
}).catch(error => {
    console.error('❌ Unexpected error:', error.message);
    process.exit(1);
});
