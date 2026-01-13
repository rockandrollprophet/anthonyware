# configs/systemd/

User-level systemd services.

Currently includes:
- cliphist.service — clipboard history daemon

Enable with:
systemctl --user enable --now cliphist.service