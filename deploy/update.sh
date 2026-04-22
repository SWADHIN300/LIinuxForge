#!/bin/bash
# ============================================================
# LinuXForge — Remote Update Script
# Run this on the EC2 server after pushing changes to GitHub.
#
# Usage:
#   ssh -i linuxforge-key.pem ubuntu@<IP> 'bash /opt/linuxforge/deploy/update.sh'
#
# Or from inside the server:
#   bash /opt/linuxforge/deploy/update.sh
# ============================================================
set -euo pipefail

cd /opt/linuxforge

echo "======================================"
echo " LinuXForge Update — $(date)"
echo "======================================"

# ── 1. Pull latest code ───────────────────────────────────────
echo "[1/4] Pulling latest from GitHub (feat/improv)..."
git fetch origin feat/improv
git reset --hard origin/feat/improv
echo "      Done. Commit: $(git log --oneline -1)"

# ── 2. Rebuild C binary (only if src/ changed) ───────────────
echo "[2/4] Rebuilding C engine..."
make -j$(nproc) CFLAGS="-Wall -Wextra -O2 -Iinclude"
chmod +x mycontainer
echo "      Binary rebuilt OK"

# ── 3. Rebuild Next.js frontend (only if frontend/ changed) ──
echo "[3/4] Rebuilding frontend..."
cd frontend
npm ci --prefer-offline
npm run build
cd ..
echo "      Frontend rebuilt OK"

# ── 4. Restart all PM2 processes (zero-downtime reload) ──────
echo "[4/4] Reloading PM2 processes..."
pm2 reload all --update-env
pm2 status

echo ""
echo "======================================"
echo " Update complete! App is back up."
echo " URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo '<your-ip>')"
echo "======================================"
