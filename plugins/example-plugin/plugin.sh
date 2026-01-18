#!/usr/bin/env bash
# Example plugin main script

echo "[PLUGIN] Example plugin loaded"

# Plugin-specific functions
example_install() {
  echo "[PLUGIN] Installing example plugin components..."
  # Add your installation logic here
}

example_configure() {
  echo "[PLUGIN] Configuring example plugin..."
  # Add your configuration logic here
}

# Export plugin functions
export -f example_install
export -f example_configure
