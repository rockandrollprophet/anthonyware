# Syncthing Configuration Template

## Setup Instructions

1. **Install Syncthing** (should already be installed via install scripts)

   ```bash
   sudo pacman -S syncthing
   ```

2. **Enable Syncthing User Service**

   ```bash
   systemctl --user enable syncthing.service
   systemctl --user start syncthing.service
   ```

3. **Access Web UI**
   Open browser to: `http://localhost:8384`

4. **Configure Template**
   - Replace `YOUR_USERNAME` with your actual username
   - Replace `YOUR_DEVICE_ID` with device ID from Syncthing GUI
   - Generate API key in Syncthing GUI (Actions → Settings → GUI → API Key)
   - Update folder paths as needed

5. **Deploy Configuration**

   ```bash
   # Backup existing config (if any)
   cp ~/.config/syncthing/config.xml ~/.config/syncthing/config.xml.backup
   
   # Copy template and edit
   cp config.xml.template ~/.config/syncthing/config.xml
   # Edit with your values
   nano ~/.config/syncthing/config.xml
   
   # Restart service
   systemctl --user restart syncthing.service
   ```

## Default Configuration

- **Web GUI**: <http://localhost:8384>
- **Sync Port**: 22000 (TCP/UDP)
- **Discovery Port**: 21027 (UDP)
- **Default Folder**: `~/Sync`
- **Theme**: Dark mode
- **Auto-upgrade**: Enabled (every 12 hours)

## Security Notes

- GUI is bound to localhost only (127.0.0.1:8384)
- TLS disabled for local-only access
- Generate a strong API key
- Review firewall rules in `../firewalld/anthonyware.xml`

## Adding Devices

1. In Syncthing GUI, click "Add Remote Device"
2. Enter Device ID of remote device
3. Configure which folders to share
4. Save and wait for connection

## Common Folders to Sync

- `~/Documents` - Personal documents
- `~/Pictures` - Photos and images
- `~/Projects` - Development projects
- `~/Config-Backup` - Configuration backups
