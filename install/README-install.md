# install/

This directory contains the full modular installation system for Anthonyware OS.

Scripts are numbered in the order they should be executed.
`run-all.sh` orchestrates the entire installation and logs output to `~/anthonyware-logs/`.

Each script is self-contained and installs one subsystem:

- base system
- GPU drivers
- Hyprland desktop
- development tools
- AI/ML stack
- CAD/CNC/3D printing stack
- electrical engineering tools
- virtualization + VFIO
- security
- backups
- power management
- firmware
- Wayland portals
- Steam/gaming
- cleanup and verification
