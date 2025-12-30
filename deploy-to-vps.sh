#!/bin/bash
# Quick Deployment Script for Video Queue Worker
# VPS: 89.117.60.144

set -e

echo "🚀 Deploying Video Queue Worker to VPS..."
echo ""

# Check if SSH key exists
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "❌ SSH key not found. Please set up SSH access to VPS first."
    echo "Run: ssh-keygen -t rsa"
    exit 1
fi

# VPS details
VPS_IP="89.117.60.144"
VPS_USER="root"
DEPLOY_DIR="/opt/queue-worker"

echo "📦 Step 1: Copying worker file to VPS..."
scp standalone-queue-worker.ts ${VPS_USER}@${VPS_IP}:/tmp/

echo "📂 Step 2: Creating deployment directory on VPS..."
ssh ${VPS_USER}@${VPS_IP} "mkdir -p ${DEPLOY_DIR} && mv /tmp/standalone-queue-worker.ts ${DEPLOY_DIR}/worker.ts"

echo "⚙️  Step 3: Creating systemd service..."
ssh ${VPS_USER}@${VPS_IP} 'cat > /etc/systemd/system/queue-worker.service << EOF
[Unit]
Description=Video Queue Worker
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/queue-worker
Environment="SUPABASE_URL=http://localhost:8001"
Environment="SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
Environment="PORT=8105"
ExecStart=/usr/bin/deno run --allow-net --allow-env /opt/queue-worker/worker.ts
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'

echo "🔄 Step 4: Enabling and starting service..."
ssh ${VPS_USER}@${VPS_IP} "systemctl daemon-reload && systemctl enable queue-worker && systemctl restart queue-worker"

echo "⏰ Step 5: Setting up cron job..."
ssh ${VPS_USER}@${VPS_IP} '(crontab -l 2>/dev/null | grep -v "queue-worker"; echo "*/1 * * * * curl -s -X POST http://localhost:8105 >> /var/log/queue-worker-cron.log 2>&1") | crontab -'

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📊 Check status:"
echo "   ssh ${VPS_USER}@${VPS_IP} 'systemctl status queue-worker'"
echo ""
echo "📝 View logs:"
echo "   ssh ${VPS_USER}@${VPS_IP} 'journalctl -u queue-worker -f'"
echo ""
echo "🧪 Test worker:"
echo "   curl http://${VPS_IP}:8105"
echo ""
