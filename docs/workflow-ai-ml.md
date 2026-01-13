# AI / ML Workflow

## 1. Create a Virtual Environment
python -m venv venv
source venv/bin/activate

## 2. PyTorch (CUDA)
Installed globally:
import torch
torch.cuda.is_available()

## 3. TensorFlow (CUDA)
import tensorflow as tf
tf.config.list_physical_devices('GPU')

## 4. HuggingFace
from transformers import AutoModel
model = AutoModel.from_pretrained("gpt2")

## 5. LLM UIs
- text-generation-webui
- oobabooga
- koboldcpp
- llama.cpp

## 6. GPU Monitoring
nvtop
