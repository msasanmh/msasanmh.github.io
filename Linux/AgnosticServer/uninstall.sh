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

echo "[✓] $SERVICE_NAME successfully uninstalled."