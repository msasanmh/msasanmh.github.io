#!/bin/bash
set -e

SERVICE_NAME="AgnosticServer"
APP_DIR="/opt/$SERVICE_NAME"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# Stop the service if it's already installed
if systemctl list-units --type=service | grep -q "$SERVICE_NAME.service"; then
    echo "⛔ Stopping existing service..."
	sudo systemctl stop "$SERVICE_NAME.service"
fi

echo "[+] Installing .NET 6 Runtime..."
sudo apt install dotnet-runtime-6.0

echo "[+] Creating app directory..."
sudo mkdir -p "$APP_DIR"
sudo cp ./$SERVICE_NAME "$APP_DIR/"
sudo cp ./$SERVICE_NAME.config "$APP_DIR/"
sudo cp ./dnss.txt "$APP_DIR/"
sudo cp ./$SERVICE_NAME.service "$SERVICE_FILE"

echo "[+] Setting permitions..."
sudo chmod +x "$APP_DIR/$SERVICE_NAME"
sudo chmod +x "$SERVICE_FILE"

echo "[+] Reloading systemd daemon..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "[+] Enabling and starting service..."
sudo systemctl enable "$SERVICE_NAME.service"
sudo systemctl start "$SERVICE_NAME.service"

echo "[✓] Installation complete. Use 'systemctl status $SERVICE_NAME' to check status."
