#!/usr/bin/env bash
# =============================================================================
# setup-runner.sh
#
# Registers a self-hosted GitHub Actions runner on your Mac (arm64).
# Run this ONCE before triggering the CI pipeline.
#
# What this does:
#   1. Downloads the runner binary from GHE
#   2. Configures it against your repo using a registration token YOU paste
#   3. Starts it in the background
#
# Usage:
#   chmod +x scripts/setup-runner.sh
#   ./scripts/setup-runner.sh
# =============================================================================
set -euo pipefail

GHE_HOST="git.viasat.com"
GHE_REPO="van/hello-world-flask"          # Change if your repo path differs
RUNNER_DIR="${HOME}/actions-runner-hello-world"
RUNNER_VERSION="2.322.0"

# ── Download ──────────────────────────────────────────────────────────────────
echo "==> Creating runner directory: ${RUNNER_DIR}"
mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

RUNNER_FILE="actions-runner-osx-arm64-${RUNNER_VERSION}.tar.gz"

if [ ! -f "${RUNNER_FILE}" ]; then
  echo "==> Downloading runner v${RUNNER_VERSION} for macOS arm64..."
  curl -Lo "${RUNNER_FILE}" \
    "https://${GHE_HOST}/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_FILE}"
else
  echo "==> Runner binary already downloaded, skipping."
fi

echo "==> Extracting..."
tar xzf "${RUNNER_FILE}"

# ── Get registration token ─────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────────────────"
echo " Get your registration token:"
echo " https://${GHE_HOST}/${GHE_REPO}/settings/actions/runners/new"
echo " Click 'New self-hosted runner' → copy the token shown."
echo "─────────────────────────────────────────────────────────────────"
echo ""
read -rsp "Paste your registration token: " REG_TOKEN
echo ""

# ── Configure ─────────────────────────────────────────────────────────────────
./config.sh \
  --url   "https://${GHE_HOST}/${GHE_REPO}" \
  --token "${REG_TOKEN}" \
  --name  "mac-$(hostname -s)" \
  --labels "self-hosted,mac,arm64" \
  --unattended \
  --replace

# ── Start ─────────────────────────────────────────────────────────────────────
echo ""
echo "==> Starting runner in the background..."
nohup ./run.sh >> "${RUNNER_DIR}/runner.log" 2>&1 &
echo $! > "${RUNNER_DIR}/runner.pid"

echo ""
echo "✅  Runner is running!"
echo ""
echo "    PID:      $(cat ${RUNNER_DIR}/runner.pid)"
echo "    Log:      tail -f ${RUNNER_DIR}/runner.log"
echo "    Stop:     kill \$(cat ${RUNNER_DIR}/runner.pid)"
echo ""
echo "    Verify it appears at:"
echo "    https://${GHE_HOST}/${GHE_REPO}/settings/actions/runners"
