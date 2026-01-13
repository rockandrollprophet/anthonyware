# VFIO Workflow

## 1. Boot into Linux host
Host uses AMD iGPU.

## 2. Start Windows VM
Launch via Virt-Manager.

## 3. GPU passthrough
NVIDIA dGPU is bound to VFIO and passed to the VM.

## 4. USB passthrough
Attach:
- 3Dconnexion
- Keyboard
- Mouse
- Dongles

## 5. Performance
Expect near-native performance for:
- SolidWorks
- Siemens NX
- TouchDesigner
- Windows-only CAD tools
