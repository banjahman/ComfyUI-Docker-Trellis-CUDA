#!/bin/bash
set -e

# Ensure core ComfyUI is happy
if [ -f "/root/ComfyUI/requirements.txt" ]; then
    python3 -m pip install --no-cache-dir --break-system-packages -r /root/ComfyUI/requirements.txt
fi

# Specialized Trellis2 check
if [ -d "/root/ComfyUI/custom_nodes/ComfyUI-Trellis2" ]; then
    echo "Detected Trellis2 - Ensuring specialized dependencies..."
    python3 -m pip install --no-cache-dir --break-system-packages \
    ninja easydict tqdm rembg
fi

if [ -d "/root/ComfyUI/custom_nodes/ComfyUI-Trellis2/cumesh" ]; then
    echo "Found local cumesh source, installing..."
    python3 -m pip install /root/ComfyUI/custom_nodes/ComfyUI-Trellis2/cumesh --break-system-packages
fi

export PYTHONPATH="${PYTHONPATH}:/root/ComfyUI/custom_nodes/ComfyUI-Trellis2"

# Standard custom nodes check
for d in /root/ComfyUI/custom_nodes/*/; do
    if [ -f "$d/requirements.txt" ]; then
        python3 -m pip install --no-cache-dir --break-system-packages -r "$d/requirements.txt"
    fi
done

# Ensure ComfyUI-Manager exists in the mapped volume
if [ ! -d "/root/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then
    echo "Installing baked-in ComfyUI-Manager..."
    cp -r /opt/ComfyUI-Manager /root/ComfyUI/custom_nodes/
fi

exec python3 /root/ComfyUI/main.py $CLI_ARGS
