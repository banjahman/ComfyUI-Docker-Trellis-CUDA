# base image
FROM nvidia/cuda:12.8.0-devel-ubuntu24.04

# environment configuration
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV COMFY_ENV_SKIP_BUILD=1
ENV COMFY_ENV_USE_SYSTEM=1
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
ENV CUDA_HOME="/usr/local/cuda"
ENV TORCH_CUDA_ARCH_LIST="8.9;9.0;10.0;12.0+PTX" 
ENV USE_NINJA=1
ENV COMFY_ENV_SKIP_BUILD=1
ENV COMFY_ENV_USE_SYSTEM=1

# install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip python3-dev python3-full git build-essential \
    ninja-build libgl1 libopengl0 libglib2.0-0 libqt5gui5 \
    libqt5core5a libqt5network5 libxrender1 \
    libeigen3-dev libegl1-mesa-dev libgles2-mesa-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/include/eigen3/Eigen /usr/include/Eigen

# python tools and torch
RUN python3 -m pip install --no-cache-dir \
    numpy setuptools wheel ninja \
    torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128

# build cumesh
RUN git clone --recursive https://github.com/visualbruno/CuMesh.git /tmp/cumesh && \
    cd /tmp/cumesh && \
    python3 -m pip install . --no-build-isolation && \
    rm -rf /tmp/cumesh

# nvdiffrast
RUN python3 -m pip install "git+https://github.com/NVlabs/nvdiffrast.git" --no-build-isolation

# trellis dependencies
RUN python3 -m pip install --no-cache-dir cumm-cu126 spconv-cu126 
RUN python3 -m pip install --no-cache-dir scipy trimesh tqdm opencv-python

# install o_voxel
RUN git clone --recursive https://github.com/microsoft/TRELLIS.2.git /tmp/trellis && \
    cd /tmp/trellis/o-voxel && \
    python3 -m pip install . --no-build-isolation && \
    cd /tmp/trellis/extensions/vox2seq && \
    python3 -m pip install . --no-build-isolation || true && \
    rm -rf /tmp/trellis

# comfyUI dependencies
RUN python3 -m pip install --no-cache-dir \
    "urllib3<2" "comfy-env>=0.2.43" "comfy-3d-viewers>=0.2.42" \
    "comfy-sparse-attn>=0.0.8" "comfy-dynamic-widgets>=0.1.6" \
    pymeshlab alembic comfy_aimdo
    
# comfyUI manager
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /opt/ComfyUI-Manager

# comfyUI source
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /root/ComfyUI
WORKDIR /root/ComfyUI

# our entry point configuration
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
