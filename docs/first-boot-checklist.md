# Anthonyware — First Boot Checklist

Use this after the first Hyprland login to make sure everything is sane.

---

## 1. Login & Desktop

- [ ] Login as your normal user (not root)
- [ ] Hyprland session starts without crashing
- [ ] Waybar appears at the top
- [ ] Kitty opens with SUPER + Enter
- [ ] Wofi opens with SUPER + Space

If any of these fail, check `~/.local/share/hypr/` logs.

---

## 2. Networking

- [ ] NetworkManager applet shows WiFi/Ethernet
- [ ] You can reach the internet:
  ```bash
  ping -c 3 archlinux.org
  ```

---

## 3. Audio

- [ ] Run pavucontrol
- [ ] Play audio in a browser or VLC
- [ ] Output device is correctly selected
- [ ] Volume keys work (if bound later)

---

## 4. GPU & Performance

In Kitty:

```bash
neofetch
glxinfo | grep "OpenGL renderer" || echo "mesa-demos not installed"
nvtop || echo "nvtop missing or NVIDIA inactive"
```

Confirm:

- [ ] AMD iGPU is used by the host for rendering
- [ ] NVIDIA dGPU is present but not driving the display if planning passthrough

---

## 5. Dev & AI

```bash
code --version
python -c "import torch; print(torch.cuda.is_available())"
```

Confirm:

- [ ] VS Code launches
- [ ] PyTorch reports True for CUDA if NVIDIA is active on host (or False if fully isolated for VFIO)

---

## 6. CAD / CNC / 3D Printing

Launch:

- [ ] Blender
- [ ] KiCad
- [ ] FreeCAD
- [ ] PrusaSlicer

Check they open without Wayland/xwayland crashes.

---

## 7. Backups

- [ ] Launch Timeshift and configure snapshot location
- [ ] Run vorta and create or point to a Borg repo
- [ ] Ensure Syncthing is running:

```bash
systemctl --user status syncthing
```

---

## 8. Security

- [ ] firewalld is active:

```bash
systemctl status firewalld
```

- [ ] KeePassXC launches
- [ ] usbguard is active:

```bash
systemctl status usbguard
```

---

## 9. Virtualization (VFIO prep)

- [ ] virt-manager launches
- [ ] systemctl status libvirtd is active
- [ ] lscpu | grep Virtualization shows VT-x or AMD-V

---

## 10. Snapshot Before Heavy Changes

Once everything looks good:

- [ ] Create a Timeshift snapshot
- [ ] Optionally run:

```bash
scripts/backup-system.sh
```

You’re now safe to start messing with VFIO, GPU passthrough, and the Windows VM.