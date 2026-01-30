#!/bin/bash
# Remove obsolete packages if installed
for pkg in waybar mako dunst swaync eww-wayland sddm alacritty wlr-randr; do
  if pacman -Qq $pkg &>/dev/null || yay -Qq $pkg &>/dev/null; then
    yay -Rns --noconfirm $pkg
  fi
done

# Install new stack and dependencies only if missing
for pkg in hyprpanel aylurs-gtk-shell-git matugen-bin python-pywayland python-gobject dart-sass greetd tuigreet nwg-look nwg-displays cairo-dock rofi-wayland nwg-drawer foot kitty swappy grim slurp nwg-menu nwg-bar nwg-launchers nwg-panel nwg-shell nwg-clipman nwg-pywall nwg-pw nwg-pw-dock nwg-pw-ctl nwg-pw-dock nwg-pw-dock-bin python-pydbus python-pyqt5 python-pyqt6 python-pyqtgraph python-pyqt5-sip python-pyqt6-sip python-pyqt-builder python-pyqtgraph-qt5 python-pyqtgraph-qt6 python-pyqtgraph-qt5-bin python-pyqtgraph-qt6-bin python-pyqtgraph-qt5-sip python-pyqtgraph-qt6-sip python-pyqtgraph-qt5-builder python-pyqtgraph-qt6-builder python-pyqtgraph-qt5-builder-bin python-pyqtgraph-qt6-builder-bin python-pyqtgraph-qt5-builder-sip python-pyqtgraph-qt6-builder-sip python-pyqtgraph-qt5-builder-sip-bin python-pyqtgraph-qt6-builder-sip-bin
