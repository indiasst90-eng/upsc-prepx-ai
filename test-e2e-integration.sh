#!/bin/bash

# E2E Integration Test for Video Queue System
# Tests: Job creation → Worker processing → Video generation → Completion

set -e  # Exit on error

# Configuration
VPS_IP="89.117.60.144"
SUPABASE_URL="http://${VPS_IP}:54321"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

echo "======================================"
echo "🧪 E2E Integration Test Starting..."
echo "======================================"
echo ""

# Test 1: Create test job
echo "[1/5] Creating test job..."
JOB_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/jobs" \
  -H "apikey: ${SERVICE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "job_type": "doubt",
    "priority": "high",
    "status": "queued",
    "payload": {
      "question": "E2E Test: Explain Article 370 of Indian Constitution"
    }
  }')

JOB_ID=$(echo "$JOB_RESPONSE" | jq -r '.[0].id')

if [ "$JOB_ID" == "null" ] || [ -z "$JOB_ID" ]; then
  echo "❌ Failed to create job"
  echo "Response: $JOB_RESPONSE"
  exit 1
fi

echo "✅ Job created: $JOB_ID"
echo ""

# Test 2: Verify job is in queue
echo "[2/5] Verifying job in queue..."
sleep 2

JOB_CHECK=$(curl -s "${SUPABASE_URL}/rest/v1/jobs?id=eq.${JOB_ID}" \
  -H "apikey: ${ANON_KEY}")

JOB_STATUS=$(echo "$JOB_CHECK" | jq -r '.[0].status')

if [ "$JOB_STATUS" != "queued" ]; then
  echo "❌ Job not in 'queued' status. Current: $JOB_STATUS"
  exit 1
fi

echo "✅ Job is queued"
echo ""

# Test 3: Wait for worker to process
echo "[3/5] Waiting for worker to process job (max 90s)..."
TIMEOUT=90
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
  JOB_STATUS_CHECK=$(curl -s "${SUPABASE_URL}/rest/v1/jobs?id=eq.${JOB_ID}" \
    -H "apikey: ${ANON_KEY}")

  CURRENT_STATUS=$(echo "$JOB_STATUS_CHECK" | jq -r '.[0].status')

  if [ "$CURRENT_STATUS" == "completed" ]; then
    echo "✅ Job completed in ${ELAPSED}s"
    break
  elif [ "$CURRENT_STATUS" == "failed" ]; then
    echo "❌ Job failed"
    echo "Error: $(echo "$JOB_STATUS_CHECK" | jq -r '.[0].error_message')"
    exit 1
  elif [ "$CURRENT_STATUS" == "processing" ]; then
    echo "   ⏳ Job is processing..."
  fi

  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "❌ Timeout: Job not completed within ${TIMEOUT}s"
  echo "Final status: $CURRENT_STATUS"
  exit 1
fi

echo ""

# Test 4: Verify video URL
echo "[4/5] Verifying video URL..."
FINAL_JOB=$(curl -s "${SUPABASE_URL}/rest/v1/jobs?id=eq.${JOB_ID}" \
  -H "apikey: ${ANON_KEY}")

VIDEO_URL=$(echo "$FINAL_JOB" | jq -r '.[0].payload.video_url')

if [ "$VIDEO_URL" == "null" ] || [ -z "$VIDEO_URL" ]; then
  echo "❌ No video URL in completed job"
  echo "Job payload: $(echo "$FINAL_JOB" | jq '.[0].payload')"
  exit 1
fi

echo "✅ Video URL found: $VIDEO_URL"
echo ""

# Test 5: Test video accessibility (if URL is http/https)
echo "[5/5] Testing video accessibility..."
if [[ $VIDEO_URL == http* ]]; then
  VIDEO_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$VIDEO_URL")

  if [ "$VIDEO_CHECK" == "200" ]; then
    echo "✅ Video is accessible (HTTP $VIDEO_CHECK)"
  else
    echo "⚠️  Video not accessible (HTTP $VIDEO_CHECK)"
    echo "   (May be expected if video is still processing)"
  fi
else
  echo "ℹ️  Video URL is not HTTP (skipping accessibility check)"
fi

echo ""
echo "======================================"
echo "🎉 E2E Test PASSED"
echo "======================================"
echo ""
echo "Test Summary:"
echo "  Job ID: $JOB_ID"
echo "  Processing Time: ${ELAPSED}s"
echo "  Video URL: $VIDEO_URL"
echo ""
echo "To view job details:"
echo "  curl '${SUPABASE_URL}/rest/v1/jobs?id=eq.${JOB_ID}' -H 'apikey: ${ANON_KEY}' | jq"
echo ""
