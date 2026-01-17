# Anthonyware Engineering & Scientific Computing Setup

## Overview

Anthonyware includes a **complete graduate-level engineering and scientific computing environment** pre-installed, with 800-900GB allocation for Arch Linux. This guide covers all engineering tools, workflows, and licensing considerations.

---

## Installed Engineering Stacks

### 1. CAD / CNC / 3D Printing (Script 07)

**Native (Arch packages):**

- **Blender**: 3D modeling, rendering, simulation, CAD workflows
- **FreeCAD**: Parametric CAD, CAM preparation
- **OpenSCAD**: Programmatic 3D design (SCAD language)
- **KiCAD**: PCB design and schematic capture

**Cloud-based:**

- **Fusion 360** (AUR): Full parametric CAD, cloud synchronization, manufacturing tools
- **Onshape** (browser): Web-based collaborative CAD
- **TinkerCAD** (browser): Educational 3D modeling

**Machining & CNC:**

- Candle, bCNC, OpenBuilds Control, Universal GCode Sender
- LaserGRBL (laser engraving)

**3D Printing:**

- Prusa Slicer, Cura (AUR), Lychee Slicer (AUR)
- OctoPrint (printer management)
- Mainsail, Fluidd (AUR) (Klipper dashboards)

**Point Cloud / Mesh:**

- MeshLab (mesh repair and processing)
- CloudCompare (AUR) (point cloud analysis)

**Windows-only CAD (via VFIO):**

- **SolidWorks**: Install in Windows VM with GPU passthrough
- **Siemens NX**: Install in Windows VM with GPU passthrough
- **CATIA, Pro/E**: Install in Windows VM as needed

---

### 2. Electrical Engineering (Script 19)

**Circuit Design & Simulation:**

- **KiCAD**: PCB layout, schematic capture
- **ngspice**: SPICE circuit simulation
- **QUCS-S**: Graphical circuit simulator
- **gEDA**: Legacy schematic capture
- **LTSpice** (AUR): Advanced SPICE simulator (requires Wine or Windows VM)

**Visualization & Analysis:**

- **Gnuplot**: Scientific plotting
- **GNU Octave**: Numerical computing (MATLAB alternative)
- **Signal processing libraries** (Python: scipy.signal)

**Hardware Debugging:**

- **sigrok-cli + PulseView**: Logic analyzer, protocol analyzer
- **OpenOCD**: JTAG/SWD debugger
- **Arduino IDE / Arduino CLI**: Microcontroller programming
- **avrdude**: AVR programming
- **ARM GCC toolchain**: Embedded ARM development

**Instrumentation:**

- **python-usbtmc**: USB Test & Measurement
- **python-pyvisa**: Instrument control (DMM, oscilloscopes, etc.)

---

### 3. FPGA / Hardware Design (Script 20)

**Open-source FPGA Flow:**

- **Yosys**: Verilog/BLIF synthesis
- **nextpnr**: Place and route for open-source FPGAs (Lattice, ECP5, iCE40)
- **iverilog**: Verilog simulation
- **GTKWave**: Waveform viewer
- **Verilator**: Fast C++ simulator
- **GHDL**: VHDL simulation

**Supported Boards:**

- iCE40 (Lattice)
- ECP5 (Lattice)
- Arty, Nexys (open variants via open-source tools)

**Xilinx/Altera Tools:**

- Install Vivado, Quartus in **Windows VM** (Windows-only, large downloads ~20-40GB each)
- Or: Use free Vivado webpack via Linux version if available

---

### 4. AI / Machine Learning / Scientific Computing (Script 06)

**Core Scientific Python:**

- NumPy, SciPy, Pandas, Scikit-learn, Scikit-image
- Matplotlib, Seaborn, Plotly, Bokeh, Altair
- SymPy (symbolic math)
- NetworkX (graph analysis)
- Statsmodels (statistical modeling)

**Deep Learning Frameworks:**

- **PyTorch** (CUDA 12.1): PyTorch, torchvision, torchaudio
- **TensorFlow** (CUDA): TensorFlow 2.15
- **HuggingFace**: Transformers, Accelerate, Datasets, Tokenizers
- **DeepSpeed**: Distributed training
- **Flash-Attention**: Fast attention mechanisms
- **Optimum, ONNX Runtime**: Model optimization

**Jupyter & Notebooks:**

- JupyterLab with LSP, Git, variable inspector, code formatter
- IPython, Notebook, ipywidgets
- Jupyter HTTP over WebSocket (remote access)

**Local LLMs (AUR):**

- text-generation-webui, koboldcpp, llama.cpp, oobabooga
- Run large language models locally on GPU

**Numerical & FEA:**

- Octave (MATLAB alternative)
- Gmsh (mesh generation)
- FEniCS (finite element analysis) — AUR
- Numba, Cython (JIT compilation)

---

### 5. Graphics / Image Processing / Rendering (Script 04)

**Image Editing:**

- **GIMP**: Raster graphics editor, photomanipulation
- **Krita**: Digital painting, concept art
- **RawTherapee**: RAW photo processing

**CLI Tools:**

- **ImageMagick**: Batch image processing, CLI manipulation
- **FFmpeg**: Video encoding, transcoding
- **optipng, jpegoptim**: Image optimization

**3D Rendering:**

- **Blender Cycles**: GPU rendering (CUDA support for NVIDIA)
- Blender Eevee: Real-time rendering

---

### 6. Virtualization / VFIO (Script 11)

**Native Linux + Windows VM with GPU Passthrough:**

- QEMU/KVM with GPU passthrough for VFIO
- Windows VM with dedicated NVIDIA dGPU
- SolidWorks, Siemens NX, Proteus, TouchDesigner run in VM
- Keyboard, mouse, 3Dconnexion dongle passed through
- **Looking Glass**: Low-latency frame capture (optional)

**Partition Layout Example:**

```bash
# /dev/nvme0n1 (1TB)
1. EFI:        512MB        (/boot)
2. Arch root:  800GB        (/)
3. Windows VM: ~188GB       (VFIO disk image)
```

---

## Disk Allocation (800-900GB)

| Component     | Size      | Purpose                         |
| ------------- | --------- | ------------------------------- |
| EFI Boot      | 512MB     | UEFI firmware, bootloader       |
| Arch Root (/) | 800-900GB | OS, all packages, user home     |
| /home         | 400-700GB | User projects, datasets, models |
| /opt          | ~50GB     | Custom builds (if needed)       |
| /var/cache    | Auto      | Package cache                   |

---

## Installation & Validation

### Partitioning

Use the included `scripts/smart-partition.sh` to automatically partition drives. See [Disk Partitioning](#disk-allocation-800-900gb) section below.

### Full Install (from USB)

```bash
# Interactive setup (creates user, asks for hostname)
bash scripts/collect-input.sh

# Run full pipeline with confirmation
CONFIRM_INSTALL=YES bash install/run-all.sh

# Monitor logs
tail -f anthonyware-logs/run-all.log
```

### Dry-run Preview

```bash
DRY_RUN=1 bash install/run-all.sh
```

### Validate Engineering Tools

After installation, verify all tools:

```bash
bash scripts/validate-engineering-tools.sh
```

Expected output: All green checkmarks for installed packages.

---

## Licensing & Commercial Software

### Free & Open-Source

- Blender, FreeCAD, OpenSCAD, KiCAD ✓ (fully included)
- GIMP, Krita, RawTherapee ✓
- PyTorch, TensorFlow, Scikit-learn ✓
- Yosys, nextpnr, Verilator ✓
- GHDL, Octave, Gmsh ✓

### Student/Institutional (require registration)

- **Fusion 360**: Free for personal use, education, and startups (limited cloud)
- **Siemens NX**: Student edition available through university (expensive commercial license ~$5000/year)
- **SolidWorks**: Student edition available through university (~$100-500/year)
- **MATLAB**: Institution may provide license (else ~$135 student/year or $2300 commercial)
- **Vivado/Quartus**: Free limited versions available

### Installation in Windows VM

```bash
# SolidWorks, Siemens NX, CATIA, Pro/E:
1. Boot Windows VM (GPU passthrough enabled)
2. Download installer from vendor (or campus software portal)
3. Install inside Windows, activate with license
4. Access files from Linux via SMB/NFS share
```

---

## Common Workflows

### CAD Design & Manufacturing

```bash
# 1. Model in Blender or Fusion 360
fusion360  # or blender

# 2. Export to STL
# 3. Slice for 3D printing
cura  # or prusa-slicer

# 4. Send to OctoPrint
# (Web interface: http://octopi.local)
```

---

### FPGA Development (open-source)

```bash
# 1. Write Verilog
vim design.v

# 2. Synthesize
yosys -p "synth_ecp5 -json design.json" design.v

# 3. Place & route
nextpnr-ecp5 --json design.json --config device.config --textcfg design.config

# 4. Simulate
iverilog -o design.vvp design.v testbench.v
vvp design.vvp
gtkwave design.vcd
```

---

### Machine Learning Training

```bash
# JupyterLab
jupyter lab

# Create notebook, run Python:
import torch
import transformers
# ... train model ...
```

---

### Circuit Simulation

```bash
# Design schematic in KiCAD
# Export netlist → ngspice
ngspice -b circuit.cir -o output.log
```

---

## Performance Notes

### GPU Acceleration

- **NVIDIA GPU required** for CUDA (AI/ML training, Blender Cycles, many scientific tools)
- AMD GPU: Uses HIP (limited support in PyTorch, TensorFlow)
- iGPU fallback: Works but slow for compute-heavy tasks

### CPU Cores

- CAD rendering: 6+ cores recommended
- ML training: More cores = better for multi-core frameworks
- FPGA synthesis: Takes 10-60 seconds on modern CPU

### RAM

- 32GB recommended for:
  - Large CAD assemblies (SolidWorks: 15GB+ possible)
  - ML model fine-tuning (e.g., 70B LLM requires 100GB+)
  - Simultaneous tools (VM + IDE + Blender)
- 16GB minimum, but expect swapping on large models

### Disk Space

- Base system: ~40GB
- Engineering tools: ~150GB
- ML datasets (ImageNet, COCO, etc.): 50-500GB+
- User projects: Unlimited

---

## Troubleshooting

### PyTorch/TensorFlow GPU not detected

```bash
# Check CUDA
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"

# May require:
pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

### Missing AUR packages (Fusion 360, Candle, etc.)

```bash
# Ensure 'yay' is installed
yay -S fusion360-bin candle

# Or build manually from AUR
git clone https://aur.archlinux.org/fusion360-bin.git
cd fusion360-bin && makepkg -si
```

### FEA/Meshing (gmsh, fenics) won't install

```bash
# Build from source if AUR fails
yay -S gmsh --noconfirm --noclean
# Or use pacman:
sudo pacman -S gmsh
```

### Windows VM (SolidWorks) performance

```bash
# Ensure:
1. GPU passthrough working: /usr/bin/gpu-passthrough-test
2. Enough VRAM allocated (8GB minimum)
3. CPU pinning configured (see vm/*.md)
4. iommu=pt in GRUB for AMD
```

---

## Next Steps

1. **First boot**: Run `scripts/first-boot-checklist.sh`
2. **Validate tools**: Run `scripts/validate-engineering-tools.sh`
3. **Test CAD**: Open Fusion 360 or Blender, load sample model
4. **Test GPU**: Run `nvidia-smi`, test CUDA in Python
5. **Configure VM** (optional): See `docs/workflow-vfio.md` and `vm/*.md`
6. **Register licenses**: Fusion 360 (free for students), SolidWorks/NX (university)

---

## References

- [Blender](https://www.blender.org/)
- [Fusion 360](https://www.autodesk.com/products/fusion-360/)
- [FreeCAD](https://www.freecadweb.org/)
- [Yosys](https://github.com/YosysHQ/yosys)
- [PyTorch](https://pytorch.org/)
- [TensorFlow](https://www.tensorflow.org/)
- [KiCAD](https://www.kicad.org/)
- [QEMU/KVM VFIO](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)

---

**Last updated**: 2025  
**Anthonyware version**: Production  
**Target audience**: Engineering students, researchers, CAD professionals, ML engineers
