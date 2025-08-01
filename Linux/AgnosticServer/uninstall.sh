#!/bin/bash
set -e

SERVICE_NAME="AgnosticServer"
APP_DIR="/opt/$SERVICE_NAME"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

echo "[-] Uninstalling $SERVICE_NAME..."

# Stop the service if running
if systemctl is-active --quiet "$SERVICE_NAME.service"; then
    echo "[-] Stopping service..."
    sudo systemctl stop "$SERVICE_NAME.service"
fi

# Disable the service if it's enable
if systemctl is-enabled --quiet "$SERVICE_NAME.service"; then
    echo "[-] Disabling service..."
    sudo systemctl disable "$SERVICE_NAME.service"
fi

# Remove service file if exist
if [ -f "$SERVICE_FILE" ]; then
    echo "[-] Removing service file..."
    sudo rm -f "$SERVICE_FILE"
	sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
fi

# Remove install directory if exist
if [ -d "$APP_DIR" ]; then
    echo "[-] Removing app directory..."
    sudo rm -rf "$APP_DIR"
fi

# Remove hostname line if we added it
if grep -qE "^127\.0\.1\.1\s+$CURRENT_HOSTNAME$" /etc/hosts; then
    echo "Removing hostname entry from /etc/hosts..."
    sudo sed -i "/^127\.0\.1\.1\s\+$CURRENT_HOSTNAME$/d" /etc/hosts
fi

# Restore backup file /etc/resolv.conf.backup
if [ -f /etc/resolv.conf.backup ]; then
    echo "Restoring original resolv.conf from backup..."
	sudo cp /etc/resolv.conf.backup /etc/resolv.conf
else
    echo "No backup resolv.conf found. Skipping restore."
fi

# Enable System DNS: Check if systemd-resolved service exists
if systemctl list-unit-files | grep -q "systemd-resolved.service"; then
    echo "🔍 Checking systemd-resolved status..."

    # Enable it if it's disabled
    if ! systemctl is-enabled --quiet systemd-resolved.service; then
        echo "✅ Enabling systemd-resolved.service..."
        sudo systemctl enable systemd-resolved.service
    fi

    # Start it if it's not running
    if ! systemctl is-active --quiet systemd-resolved.service; then
        echo "▶️ Starting systemd-resolved.service..."
        sudo systemctl start systemd-resolved.service
    fi
	
	# Restart
	echo "▶️ Restarting systemd-resolved.service..."
	sudo systemctl restart systemd-resolved.service
	
else
    echo "⚠️ systemd-resolved.service not found on this system."
fi

echo "[✓] $SERVICE_NAME successfully uninstalled."