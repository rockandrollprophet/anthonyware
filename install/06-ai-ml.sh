#!/usr/bin/env bash
set -euo pipefail

echo "=== [06] AI / Machine Learning Stack ==="

# CUDA + cuDNN already installed in GPU script
sudo pacman -S --noconfirm --needed \
    python \
    python-pip \
    python-numpy \
    python-scipy \
    python-pandas \
    python-matplotlib \
    python-scikit-learn \
    python-jupyterlab \
    python-seaborn \
    python-tqdm \
    python-requests \
    python-virtualenv \
    python-ipykernel \
    python-nbformat \
    python-nbconvert \
    python-jupyterlab-server \
    python-ipywidgets \
    nvtop

# PyTorch (CUDA)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# TensorFlow (CUDA)
pip install tensorflow==2.15 tensorflow-io-gcs-filesystem

# HuggingFace + LLM tooling
pip install \
    transformers \
    accelerate \
    datasets \
    tokenizers \
    bitsandbytes \
    optimum \
    onnxruntime-gpu \
    deepspeed \
    flash-attn \
    sentencepiece

# JupyterLab tooling / LSP / Git / utility extensions
echo "[06-ai-ml] Installing JupyterLab extensions via pip (LSP, git, tooling)..."

pip install --upgrade \
    jupyterlab-lsp \
    python-lsp-server \
    jupyterlab-git \
    jupyterlab-variableinspector \
    jupyterlab-code-formatter \
    jupyterlab_execute_time \
    jupyter_http_over_ws

# LLM UIs (AUR)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        text-generation-webui \
        koboldcpp \
        llama.cpp \
        oobabooga || echo "WARNING: Some LLM UIs failed to build via yay"
else
    echo "NOTICE: 'yay' not found; install LLM UI packages via AUR helper if desired"
fi

# GPU monitoring
sudo pacman -S --noconfirm --needed nvtop || echo "WARNING: nvtop install failed"

echo "=== AI/ML Stack Setup Complete ==="