#!/bin/bash
set -e

# 1. Function to deploy baked-in nodes to the mapped volume
deploy_node() {
    local node_name=$1
    if [ ! -d "/root/ComfyUI/custom_nodes/$node_name" ]; then
        echo "Deploying baked-in $node_name..."
        cp -r "/opt/$node_name" "/root/ComfyUI/custom_nodes/"
    else
        echo "$node_name already present, skipping deployment."
    fi
}

# 2. Deploy our Blackwell-optimized stack
# Make sure your Dockerfile clones these into /opt/
deploy_node "ComfyUI-Manager"
deploy_node "ComfyUI-GeometryPack"
deploy_node "ComfyUI-Trellis2"

# 3. Environment Setup
# Trellis nodes often need to find their own internal modules
export PYTHONPATH="${PYTHONPATH}:/root/ComfyUI/custom_nodes/ComfyUI-Trellis2"

# 4. Requirements Sync
# This checks all custom nodes and installs missing requirements.
# Since our Dockerfile already has the "hard" stuff, this will usually 
# skip quickly unless you added a brand-new node to your host folder.
echo "Checking for missing custom node dependencies..."
for d in /root/ComfyUI/custom_nodes/*/; do
    if [ -f "$d/requirements.txt" ]; then
        echo "Installing requirements for $(basename "$d")..."
        python3 -m pip install --no-cache-dir --break-system-packages -r "$d/requirements.txt"
    fi
done

if [ -f "/root/ComfyUI/requirements.txt" ]; then
    echo "Ensuring base ComfyUI requirements are met..."
    python3 -m pip install --no-cache-dir --break-system-packages -r /root/ComfyUI/requirements.txt
fi

# Nuke any local venvs created by custom nodes to force them to use the system Python
find /root/ComfyUI/custom_nodes -name "ComfyEnv" -type d -exec rm -rf {} + 2>/dev/null

# The path where visualbruno looks for the Trellis 2 weights
CHECKPOINT_DIR="/root/ComfyUI/models/checkpoints/TRELLIS.2-4B"
MAIN_WEIGHTS="$CHECKPOINT_DIR/ckpts/diffusion_model.safetensors"

if [ -f "$MAIN_WEIGHTS" ]; then
    echo "--- [SKIP] Trellis 2 Weights already present. Using existing files. ---"
else
    echo "--- [AUTO] Trellis 2 Weights not found. Starting download (15GB)... ---"
    python3 -c "
from huggingface_hub import snapshot_download
import os

# Create the folder structure if it doesn't exist
os.makedirs('$CHECKPOINT_DIR', exist_ok=True)

snapshot_download(
    repo_id='microsoft/TRELLIS.2-4B',
    local_dir='$CHECKPOINT_DIR',
    # We only pull the necessary weights and configs to save time/space
    allow_patterns=['*.safetensors', '*.json', 'ckpts/*.safetensors']
)"
fi

# facebook DINO lib
DINO_PATH="/root/ComfyUI/models/facebook/dinov3-vitl16-pretrain-lvd1689m"
DINO_FILE="$DINO_PATH/model.safetensors"

if [ -f "$DINO_FILE" ]; then
    echo "--- [SKIP] DINOv3 Weights already present. ---"
else
    echo "--- [AUTO] DINOv3 not found. Downloading... ---"
    python3 -c "
from huggingface_hub import snapshot_download
import os

token = os.getenv('HF_TOKEN')
snapshot_download(
    repo_id='facebook/dinov3-vitl16-pretrain-lvd1689m',
    local_dir='$DINO_PATH',
    token=token,
    allow_patterns=['*.safetensors', '*.json']
)"
fi

# 5. Launch
echo "--- Launching ComfyUI on Blackwell Architecture ---"
# Using $CLI_ARGS allows you to pass flags like --fp8_e4m3fn from docker-compose
exec python3 /root/ComfyUI/main.py --listen 0.0.0.0 --port 8188 $CLI_ARGS
