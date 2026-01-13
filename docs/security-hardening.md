# Anthonyware Security Hardening

## 1. Firewall
sudo firewall-cmd --set-default-zone=public
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload

## 2. AppArmor
Profiles live in `/etc/apparmor.d/`.

## 3. Firejail
Run apps sandboxed:
firejail vivaldi-stable

## 4. USBGuard
Block all new USB devices:
sudo usbguard generate-policy > /etc/usbguard/rules.conf
sudo systemctl restart usbguard

## 5. Fail2ban
Protect SSH brute force.

## 6. Password Manager
Use KeePassXC with a YubiKey if possible.

## 7. Disk Encryption
Use LUKS on next reinstall.
