# Anthonyware Engineering Workstation - What's Pre-installed

## TL;DR

**Anthonyware gives you a complete engineering and scientific computing environment out of the box.** Everything below is already installed when you finish the install pipeline.

---

## Quick Facts

- **OS**: Arch Linux with Hyprland (tiling compositor)
- **Pre-installed packages**: 260+ from pacman + 20+ from AUR
- **Disk size**: 800-900GB allocation for Arch partition
- **Target audience**: Graduate students, engineers, ML researchers, CAD professionals
- **Licensing**: All open-source + free tools included; commercial tools (SolidWorks, NX) run in optional Windows VM
- **First-time setup**: ~30-60 minutes (download ~15-20GB of packages)

---

## Pre-installed Engineering Environments

### CAD / Design (Native & Cloud)

| Tool | Type | Status | Notes |
| --- | --- | --- | --- |
| **Fusion 360** | Cloud/hybrid | ✓ Installed (AUR) | Free for students; requires Autodesk account |
| **Blender** | Open-source | ✓ Installed | Full 3D modeling, rendering, CAM |
| **FreeCAD** | Open-source | ✓ Installed | Parametric CAD, CAM workbench |
| **OpenSCAD** | Open-source | ✓ Installed | Programmatic 3D design |
| **KiCAD** | Open-source | ✓ Installed | PCB design, schematic capture |
| **SolidWorks** | Windows-only | VM optional | Install in Windows VM via VFIO |
| **Siemens NX** | Windows-only | VM optional | Install in Windows VM via VFIO |
| **Onshape** | Web-based | Via browser | Free with Zenity Browser included |

### Machining & CNC

- Candle, bCNC, OpenBuilds Control, Universal GCode Sender, LaserGRBL
- Full G-code simulation and machine control

### 3D Printing

- Prusa Slicer, Cura, Lychee Slicer
- OctoPrint + Mainsail/Fluidd for printer management
- Mesh editing (MeshLab, CloudCompare)

---

### Electrical Engineering

| Tool | Category | Status |
| --- | --- | --- |
| **KiCAD** | PCB design | ✓ Installed |
| **ngspice** | Circuit simulation | ✓ Installed |
| **QUCS-S** | Circuit simulator (GUI) | ✓ Installed |
| **GNU Octave** | Numerical computing | ✓ Installed |
| **sigrok + PulseView** | Logic analyzer | ✓ Installed |
| **Arduino CLI** | Microcontroller | ✓ Installed |
| **ARM GCC toolchain** | Embedded development | ✓ Installed |
| **OpenOCD** | JTAG debugging | ✓ Installed |
| **Python USB/VISA** | Instrument control | ✓ Installed |

---

### FPGA / HDL Design

| Tool | Status | Purpose |
| --- | --- | --- |
| **Yosys** | ✓ Installed | Verilog synthesis |
| **nextpnr** | ✓ Installed | Place and route (open FPGAs) |
| **iverilog** | ✓ Installed | Verilog simulation |
| **GTKWave** | ✓ Installed | Waveform viewing |
| **Verilator** | ✓ Installed | Fast C++ simulator |
| **GHDL** | ✓ Installed | VHDL simulation |
| **Xilinx Vivado** | Optional | Install in Windows VM (~30GB) |
| **Intel Quartus** | Optional | Install in Windows VM (~20GB) |

---

### AI / Machine Learning / Scientific Computing

| Framework | Status | GPU Support |
| --- | --- | --- |
| **PyTorch** | ✓ Installed | CUDA 12.1 |
| **TensorFlow** | ✓ Installed | CUDA 12.1 |
| **Transformers (HuggingFace)** | ✓ Installed | Yes |
| **DeepSpeed** | ✓ Installed | Distributed training |
| **Jupyter Lab** | ✓ Installed | Full extensions (LSP, Git, formatter) |
| **NumPy, SciPy, Pandas** | ✓ Installed | Scientific computing |
| **Scikit-learn** | ✓ Installed | Machine learning |
| **Matplotlib, Plotly, Bokeh** | ✓ Installed | Data visualization |
| **SymPy** | ✓ Installed | Symbolic math |
| **Gmsh** | ✓ Installed | Mesh generation |
| **Octave** | ✓ Installed | MATLAB alternative |
| **Local LLMs** | ✓ Installed (AUR) | text-generation-webui, koboldcpp, llama.cpp |

---

### Image Processing & Graphics

| Tool | Type | Status |
| --- | --- | --- |
| **GIMP** | Raster editor | ✓ Installed |
| **Krita** | Digital painting | ✓ Installed |
| **RawTherapee** | RAW processing | ✓ Installed |
| **ImageMagick** | CLI tools | ✓ Installed |
| **FFmpeg** | Video codec | ✓ Installed |
| **Blender (Cycles)** | 3D rendering | ✓ Installed |

---

### Development Tools (Base System)

| Category | Tools | Status |
| --- | --- | --- |
| **Version Control** | Git, Git-LFS, GitHub CLI | ✓ Installed |
| **Build Systems** | CMake, Meson, Ninja, Make | ✓ Installed |
| **Compilers** | GCC, Clang, LLVM | ✓ Installed |
| **Languages** | Python 3, Zsh, Bash, Nushell | ✓ Installed |
| **Containers** | Docker, Podman, Docker Compose | ✓ Installed |
| **Debugging** | GDB, Valgrind, LLDB, Strace | ✓ Installed |
| **Package Managers** | paru, yay (AUR) | ✓ Installed |
| **Code Formatters** | shellcheck, shfmt, prettier | ✓ Installed |
| **Monitoring** | htop, btop, iotop, nethogs | ✓ Installed |
| **File Tools** | ripgrep, fd, bat, fzf | ✓ Installed |

---

### Virtualization & VFIO (Windows VM)

| Tool | Purpose | Status |
| --- | --- | --- |
| **QEMU/KVM** | Hypervisor | ✓ Installed |
| **Virt-Manager** | VM management GUI | ✓ Installed |
| **Looking Glass** | Low-latency frame capture | ✓ Installed (AUR) |
| **OVMF/UEFI** | Firmware for VM | ✓ Installed |
| **VirtIO drivers** | Windows drivers | ✓ Installed |
| **libvirt** | VM orchestration | ✓ Installed |

**Use case**: Run SolidWorks, Siemens NX, Proteus with near-native GPU performance on NVIDIA dGPU.

---

## Not Pre-installed (Licensing)

These require institutional or purchased licenses:

- **SolidWorks** (Professional CAD) → Install in Windows VM
- **Siemens NX** (Professional CAD) → Install in Windows VM
- **CATIA** (Advanced CAD) → Install in Windows VM
- **MATLAB** (Commercial) → University license or $135/year student
- **Vivado/Quartus** (Xilinx/Intel FPGA) → Free limited versions, install separately
- **Adobe Suite** → Not included, use GIMP/Krita/RawTherapee instead

---

## Validation & Testing

After installation, verify everything works:

```bash
# Comprehensive tool check
bash scripts/validate-engineering-tools.sh

# Quick test: Run Python ML framework
python -c "import torch; print(torch.cuda.is_available())"

# Blender test
blender --version

# FPGA tools
yosys -version
```

Expected: All green checkmarks ✓

---

## Storage & Performance

### Disk Usage

| Component | Space |
| --- | --- |
| Base system (OS + packages) | ~40GB |
| Engineering tools | ~150GB |
| Remaining for user files | 610-810GB |

### GPU Acceleration

- **NVIDIA**: CUDA 12.1 drivers installed; use for PyTorch, TensorFlow, Blender
- **AMD**: HIP support (limited); ROCm may be installed separately
- **Intel iGPU**: Fallback (slow for compute)

### RAM Recommendation

- **Minimum**: 16GB (for small CAD, light ML)
- **Recommended**: 32GB (for large assemblies, model training, VM)
- **Ideal**: 64GB+ (for serious ML, multiple VMs)

---

## Workflows Enabled

1. **Mechanical Engineering**: CAD (Fusion 360/FreeCAD) → CAM (FreeCAD) → CNC control
2. **Electrical**: Schematic (KiCAD) → Simulation (ngspice) → PCB layout → Manufacturing
3. **FPGA**: Write Verilog → Synthesize (Yosys) → P&R (nextpnr) → Simulate/Deploy
4. **ML Research**: Jupyter → PyTorch/TensorFlow → GPU training → Results plotting
5. **3D Printing**: Design (Blender/CAD) → Slice (Cura) → OctoPrint → Print
6. **Rendering**: Model (Blender) → Render (Cycles) → Post-process (GIMP) → Export

---

## Getting Help

1. **Validation script**: `scripts/validate-engineering-tools.sh`
2. **Documentation**: `docs/engineering-setup.md`
3. **Workflow guides**: `docs/workflow-*.md` (CAD, AI/ML, VFIO, etc.)
4. **Troubleshooting**: `docs/install-guide.md#Troubleshooting`

---

## Estimated Install Time

| Phase | Time |
| --- | --- |
| Base system + packages | 15-25 min |
| GPU drivers | 5-10 min |
| Hyprland + DE | 5-10 min |
| Engineering tools | 10-20 min |
| AI/ML frameworks | 10-15 min |
| **Total** | **45-80 min** |

(Depends on internet speed and hardware; faster on newer CPUs and SSDs)

---

## Summary

You get:

- ✓ Professional CAD (Fusion 360, Blender, FreeCAD)
- ✓ Full FPGA/HDL toolchain (open-source)
- ✓ Complete ML/AI stack (PyTorch, TensorFlow, Jupyter)
- ✓ Advanced EE tools (KiCAD, ngspice, oscilloscope control)
- ✓ 3D printing ecosystem
- ✓ High-performance dev environment (260+ packages)
- ✓ Optional Windows VM for proprietary CAD (SolidWorks, NX)

**No additional installation needed after first boot.**

Enjoy building! 🛠️
