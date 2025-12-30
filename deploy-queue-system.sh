#!/bin/bash
# Video Queue Management - VPS Deployment Script
# VPS: 89.117.60.144
# Run this script to deploy the queue system to production

set -e

echo "🚀 Starting Video Queue Management Deployment..."
echo "VPS: 89.117.60.144"
echo ""

# Configuration
VPS_IP="89.117.60.144"
SUPABASE_URL="http://89.117.60.144:54321"
SUPABASE_PORT="54321"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Checking Supabase Connection...${NC}"
curl -s http://${VPS_IP}:3000 > /dev/null && echo -e "${GREEN}✅ Supabase Studio accessible${NC}" || echo -e "${RED}❌ Supabase Studio not accessible${NC}"

echo ""
echo -e "${YELLOW}Step 2: Deploying Database Migration...${NC}"
echo "Run this command manually:"
echo -e "${GREEN}cd packages/supabase && supabase db push --db-url postgresql://postgres:postgres@${VPS_IP}:5432/postgres${NC}"

echo ""
echo -e "${YELLOW}Step 3: Verify Migration...${NC}"
echo "Connect to database and run:"
echo -e "${GREEN}SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('jobs', 'job_queue_config');${NC}"

echo ""
echo -e "${YELLOW}Step 4: Deploy Edge Function...${NC}"
echo "Run this command:"
echo -e "${GREEN}cd packages/supabase && supabase functions deploy video-queue-worker --project-ref your-project-ref${NC}"

echo ""
echo -e "${YELLOW}Step 5: Configure Cron Job...${NC}"
echo "Option A - Supabase Dashboard:"
echo "  1. Go to http://${VPS_IP}:3000"
echo "  2. Navigate to Edge Functions"
echo "  3. Select 'video-queue-worker'"
echo "  4. Add Cron: */1 * * * *"
echo ""
echo "Option B - System Cron (if Edge Functions cron not available):"
echo "  Run: crontab -e"
echo "  Add: */1 * * * * curl -X POST http://${VPS_IP}:54321/functions/v1/video-queue-worker"

echo ""
echo -e "${YELLOW}Step 6: Test Queue System...${NC}"
echo "Run the test script: ./test-queue-system.sh"

echo ""
echo -e "${GREEN}✅ Deployment instructions complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Execute the migration command above"
echo "2. Deploy the Edge Function"
echo "3. Configure the cron job"
echo "4. Run the test script"
echo "5. Access monitoring dashboard"
