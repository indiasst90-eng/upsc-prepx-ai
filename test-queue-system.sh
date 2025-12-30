#!/bin/bash
# Test Video Queue Management System
# VPS: 89.117.60.144

set -e

VPS_IP="89.117.60.144"
SUPABASE_URL="http://${VPS_IP}:54321"
SUPABASE_ANON_KEY="your-anon-key-here"

echo "🧪 Testing Video Queue Management System..."
echo ""

# Test 1: Check if tables exist
echo "Test 1: Checking database tables..."
psql "postgresql://postgres:postgres@${VPS_IP}:5432/postgres" -c "SELECT COUNT(*) FROM jobs;" > /dev/null 2>&1 && echo "✅ jobs table exists" || echo "❌ jobs table missing"
psql "postgresql://postgres:postgres@${VPS_IP}:5432/postgres" -c "SELECT COUNT(*) FROM job_queue_config;" > /dev/null 2>&1 && echo "✅ job_queue_config table exists" || echo "❌ job_queue_config table missing"

echo ""

# Test 2: Insert test job
echo "Test 2: Inserting test job..."
TEST_JOB=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/jobs" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "job_type": "doubt",
    "priority": "high",
    "status": "queued",
    "payload": {"question": "Test question from deployment script"},
    "retry_count": 0,
    "max_retries": 3
  }')

if [ ! -z "$TEST_JOB" ]; then
  echo "✅ Test job created"
  JOB_ID=$(echo $TEST_JOB | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
  echo "   Job ID: $JOB_ID"
else
  echo "❌ Failed to create test job"
fi

echo ""

# Test 3: Check queue statistics
echo "Test 3: Checking queue statistics..."
STATS=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/rpc/get_queue_stats" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json")

if [ ! -z "$STATS" ]; then
  echo "✅ Queue statistics retrieved"
  echo "   Stats: $STATS"
else
  echo "❌ Failed to get queue statistics"
fi

echo ""

# Test 4: Check worker function
echo "Test 4: Testing worker function..."
WORKER_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/video-queue-worker" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}")

if [ ! -z "$WORKER_RESPONSE" ]; then
  echo "✅ Worker function responding"
  echo "   Response: $WORKER_RESPONSE"
else
  echo "❌ Worker function not responding"
fi

echo ""
echo "🎉 Testing complete!"
echo ""
echo "Manual verification steps:"
echo "1. Check Supabase Studio: http://${VPS_IP}:3000"
echo "2. View jobs table: SELECT * FROM jobs ORDER BY created_at DESC LIMIT 10;"
echo "3. View queue stats: SELECT * FROM get_queue_stats();"
echo "4. Access monitoring dashboard (once deployed)"
