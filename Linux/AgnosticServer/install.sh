#!/bin/bash
set -e

SERVICE_NAME="AgnosticServer"
APP_DIR="/opt/$SERVICE_NAME"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# Stop the service if it's already installed and enable system DNS
if systemctl list-units --type=service | grep -q "$SERVICE_NAME.service"; then
    echo "⛔ Stopping existing service..."
	sudo systemctl stop "$SERVICE_NAME.service"
	# Enable system DNS: Check if systemd-resolved service exists
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
		
		echo "▶️ Restarting systemd-resolved.service..."
		sudo systemctl restart systemd-resolved.service
		
	else
		echo "⚠️ systemd-resolved.service not found on this system."
	fi
	
	# Restore backup file /etc/resolv.conf.backup
	if [ -f /etc/resolv.conf.backup ]; then
		echo "Restoring original resolv.conf from backup..."
		sudo cp /etc/resolv.conf.backup /etc/resolv.conf
		echo "[+] Reloading systemd daemon..."
		sudo systemctl daemon-reexec
		sudo systemctl daemon-reload
	else
		echo "No backup resolv.conf found. Skipping restore."
	fi
	
fi

echo "[+] Installing .NET 6 Runtime..."
sudo apt install dotnet-runtime-6.0

echo "[+] Creating app directory..."
sudo mkdir -p "$APP_DIR"
sudo cp ./$SERVICE_NAME "$APP_DIR/"
sudo cp ./$SERVICE_NAME.config "$APP_DIR/"
sudo cp ./dnss.txt "$APP_DIR/"
sudo cp ./dnss5353.txt "$APP_DIR/"
sudo cp ./$SERVICE_NAME.service "$SERVICE_FILE"

echo "[+] Setting permitions..."
sudo chmod +x "$APP_DIR/$SERVICE_NAME"
sudo chmod +x "$SERVICE_FILE"

# Fix hostname resolution issue
CURRENT_HOSTNAME=$(hostname)
if ! grep -q "$CURRENT_HOSTNAME" /etc/hosts; then
    echo "Fixing /etc/hosts for hostname resolution..."
    echo "127.0.1.1 $CURRENT_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi

# Disable system DNS to make port 53 free
if systemctl list-unit-files | grep -q "systemd-resolved.service"; then
    echo "🔍 Checking systemd-resolved status..."

    # Stop it if it's running
    if systemctl is-active --quiet systemd-resolved.service; then
        echo "[-] Stopping systemd-resolved.service..."
        sudo systemctl stop systemd-resolved.service
    fi
	
	# Disable it if it's enabled
    if systemctl is-enabled --quiet systemd-resolved.service; then
        echo "[-] Disabling systemd-resolved.service..."
        sudo systemctl disable systemd-resolved.service
    fi
else
    echo "⚠️ systemd-resolved.service not found on this system."
fi

echo "[+] Reloading systemd daemon..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "[+] Enabling and starting service..."
sudo systemctl enable "$SERVICE_NAME.service"
sudo systemctl start "$SERVICE_NAME.service"

echo "[✓] Installation complete. Use 'systemctl status $SERVICE_NAME' to check status."
