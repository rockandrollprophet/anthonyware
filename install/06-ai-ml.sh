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
    python-virtualenv

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

# LLM UIs (AUR)
yay -S --noconfirm --needed \
    text-generation-webui \
    koboldcpp \
    llama.cpp \
    oobabooga

# GPU monitoring
sudo pacman -S --noconfirm --needed nvtop

echo "=== AI/ML Stack Setup Complete ==="