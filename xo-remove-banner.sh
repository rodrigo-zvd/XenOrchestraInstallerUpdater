#!/bin/bash

# This script removes banners and warnings from a Xen Orchestra installation
# created by the XenOrchestraInstallerUpdater script.
# It should be run AFTER a successful installation or update.
# https://github.com/ronivay/XenOrchestraInstallerUpdater/issues/28

set -euo pipefail

# Check if the script is run as root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Error: This script must be run as root. Please run with sudo."
    exit 1
fi

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/xo-install.cfg"

# Source script configuration variables.
# shellcheck disable=SC1090
source "$CONFIG_FILE"

# Set default INSTALLDIR if not found in config
INSTALLDIR=${INSTALLDIR:-"/opt/xo"}
YARN_NETWORK_TIMEOUT=${YARN_NETWORK_TIMEOUT:-"300000"}
PORT=${PORT:-80}
INCLUDE_V6=${INCLUDE_V6:-"false"}

# Find the most recent installation directory
echo "Searching for the latest Xen Orchestra build..."
LATEST_BUILD_DIR=$(find "$INSTALLDIR/xo-builds/" -maxdepth 1 -type d -name 'xen-orchestra-*' -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2- | head -n1)

if [[ -z "$LATEST_BUILD_DIR" ]]; then
    echo "No Xen Orchestra installation found in $INSTALLDIR/xo-builds/"
    exit 1
fi

echo "Found latest installation at: $LATEST_BUILD_DIR"

# Apply modifications
echo "Applying modifications to remove banners and warnings..."

# --- Modify xo-web src ---
echo "Patching xo-web..."
WEB_APP_DIR="$LATEST_BUILD_DIR/packages/xo-web/src/xo-app"
sed -i 's/this.displayOpenSourceDisclaimer()/ /gi' "$WEB_APP_DIR/index.js"
sed -i 's/!this.state.dismissedSourceBanner/false/gi' "$WEB_APP_DIR/index.js"

# --- Modify menu ---
echo "Patching the menu..."
MENU_DIR="$WEB_APP_DIR/menu"
sed -i "s/<UpdateTag key='update' \/>/null/gi" "$MENU_DIR/index.js"
sed -i "s/extra: <UpdateTag \/>,/ /gi" "$MENU_DIR/index.js"
sed -i "s/process.env.XOA_PLAN === 5 ?/process.env.XOA_PLAN === 99 ?/gi" "$MENU_DIR/index.js"

# --- Modify home items ---
echo "Patching home items..."
HOME_DIR="$WEB_APP_DIR/home"
sed -i "s/supportLevel !== 'total'/false/gi" "$HOME_DIR/pool-item.js"
sed -i "s/proSupportStatus !== undefined && proSupportStatus.level !== 'success'/false/gi" "$HOME_DIR/host-item.js"

echo "Modifications applied."

# Stop Xen Orchestra service before building
echo "Stopping xo-server service..."
if command -v systemctl >/dev/null && systemctl is-active --quiet xo-server; then
    systemctl stop xo-server
    echo "xo-server service stopped."
fi

# Rebuild Xen Orchestra to apply changes
echo "Rebuilding Xen Orchestra to apply changes. This may take a few minutes..."
cd "$LATEST_BUILD_DIR"
yarn --network-timeout "${YARN_NETWORK_TIMEOUT}" && yarn --network-timeout "${YARN_NETWORK_TIMEOUT}" build
if [[ "${INCLUDE_V6:-false}" == "true" ]]; then
    echo "INCLUDE_V6 is true, running additional web build..."
    yarn --network-timeout "${YARN_NETWORK_TIMEOUT}" run turbo run build --filter @xen-orchestra/web
fi

echo "Build complete."

# Start and verify Xen Orchestra service
echo "Starting xo-server service..."
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
systemctl start xo-server

echo "Verifying service startup..."
count=0
limit=6 # 6 * 10s = 60s total wait time
servicestatus=""

# Loop service logs for 60 seconds to verify it started
while [[ -z "$servicestatus" ]] && [[ "$count" -lt "$limit" ]]; do
    # Grep for the listening message in journalctl
    servicestatus=$(journalctl --since "$LOGTIME" -u xo-server | grep "Web server listening on https\{0,1\}:\/\/.*:$PORT" || true)
    if [[ -n "$servicestatus" ]]; then
        break
    fi
    echo "Waiting for xo-server to be ready... ($((count+1))/$limit)"
    sleep 10
    ((count++))
done

# Check if service started successfully
if [[ -n "$servicestatus" ]]; then
    echo "Service started successfully and is listening on port $PORT."
    echo "Enabling service to start on reboot."
    systemctl enable xo-server
else
    echo "Error: Task completed, but xo-server failed to start."
    echo "Please check the logs for more details with the command: journalctl -u xo-server --since '$LOGTIME'"
    exit 1
fi

echo "All done. Banners should now be removed from your Xen Orchestra UI."
