#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [06] AI / Machine Learning / Scientific Computing Stack ==="

# CUDA + cuDNN already installed in GPU script
# Core scientific Python stack
${SUDO} pacman -S --noconfirm --needed \
    python \
    python-pip \
    python-numpy \
    python-scipy \
    python-pandas \
    python-matplotlib \
    python-scikit-learn \
    python-scikit-image \
    python-jupyterlab \
    python-seaborn \
    python-tqdm \
    python-requests \
    python-virtualenv \
    python-ipykernel \
    python-nbformat \
    python-nbconvert \
    python-jupyterlab_server \
    python-ipywidgets \
    python-sympy \
    python-networkx \
    python-shapely \
    python-plotly \
    nvtop

# GPU monitoring and profiling
${SUDO} pacman -S --noconfirm --needed \
    cuda-tools || echo "WARNING: cuda-tools install failed"

# PyTorch (CUDA)
echo "[06] Installing PyTorch with CUDA support..."
echo "     This may take 5-10 minutes depending on network speed..."
if ! pip install --progress-bar on torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 2>&1 | tee /tmp/pytorch-install.log; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "ERROR: PyTorch installation failed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Common causes:"
  echo "  • Network timeout or slow connection"
  echo "  • Insufficient disk space (need ~5GB)"
  echo "  • CUDA version mismatch"
  echo ""
  echo "Troubleshooting:"
  echo "  • Check disk space: df -h"
  echo "  • View full log: less /tmp/pytorch-install.log"
  echo "  • Retry manually: pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121"
  echo ""
  exit 1
fi
echo "✓ PyTorch installed successfully"

# TensorFlow (CUDA)
echo ""
echo "[06] Installing TensorFlow with CUDA support..."
echo "     This may take 3-5 minutes..."
if ! pip install --progress-bar on tensorflow==2.15 tensorflow-io-gcs-filesystem 2>&1; then
  echo "⚠ TensorFlow installation failed (non-fatal)"
  echo "  You can install manually later if needed"
else
  echo "✓ TensorFlow installed successfully"
fi

# HuggingFace + LLM tooling
echo ""
echo "[06] Installing HuggingFace + LLM ecosystem..."
echo "     This may take 5-7 minutes..."
if pip install --progress-bar on \
    transformers \
    accelerate \
    datasets \
    tokenizers \
    bitsandbytes \
    optimum \
    onnxruntime-gpu \
    deepspeed \
    flash-attn \
    sentencepiece 2>&1; then
  echo "✓ HuggingFace ecosystem installed"
else
  echo "⚠ Some HuggingFace packages failed (continuing)"
fi

# Scientific computing + numerical methods
echo "[06] Installing scientific computing libraries..."
pip install \
    sympy \
    mpmath \
    pytest \
    hypothesis \
    numba \
    cython \
    statsmodels

# Jupyter plugins and extensions
echo "[06] Installing JupyterLab extensions (LSP, git, tooling)..."

pip install --upgrade \
    jupyterlab-lsp \
    python-lsp-server \
    jupyterlab-git \
    jupyterlab-variableinspector \
    jupyterlab-code-formatter \
    jupyterlab_execute_time \
    jupyter_http_over_ws

# Data visualization (advanced)
pip install \
    altair \
    bokeh \
    holoviews \
    datashader

# Finite element / mesh analysis
if command -v yay >/dev/null; then
    echo "[06] Installing FEA/meshing tools..."
    yay -S --noconfirm --needed \
        gmsh \
        fenics || echo "WARNING: Some FEA tools failed to install"
else
    echo "NOTICE: 'yay' not found; install gmsh/fenics via pacman if available"
fi

# LLM UIs (AUR)
if command -v yay >/dev/null; then
    echo "[06] Installing local LLM UIs..."
    yay -S --noconfirm --needed \
        text-generation-webui \
        koboldcpp \
        llama.cpp \
        oobabooga || echo "WARNING: Some LLM UIs failed to build via yay"
else
    echo "NOTICE: 'yay' not found; install LLM UI packages via AUR helper if desired"
fi

echo "=== AI/ML/Scientific Computing Stack Setup Complete ==="