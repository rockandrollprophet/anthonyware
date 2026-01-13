# TouchDesigner Setup (Windows VM)

TouchDesigner runs inside the Windows VM with GPU passthrough.

## Steps:
1. Install NVIDIA drivers inside Windows.
2. Install TouchDesigner normally.
3. Enable hardware acceleration.
4. For multi-GPU setups, ensure the VM GPU is the primary adapter.
5. Use Looking Glass for low-latency preview if desired.

TouchDesigner performs at near-native speed under VFIO.
