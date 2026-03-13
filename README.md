# ComfyUI-Trellis2-Blackwell-Docker

A high-performance, containerized ComfyUI environment specifically engineered for **NVIDIA Blackwell (RTX 50-Series)** GPUs. This build solves the complex compilation requirements for **TRELLIS 2** and other 3D generative nodes on latest-gen hardware.

## 🚀 Optimized for RTX 5070 Ti / 5080 / 5090
This configuration is the result of intensive debugging to align CUDA 12.8, Python 3.12+, and the Blackwell architecture. It bakes heavy CUDA kernels directly into the image layers to ensure "instant-on" performance and runtime stability. 

This was developed with driver version 590.48.01 (CUDA 13.1) but at the time of creation, dependencies haven't implemented CUDA 13, so it's compiled against the 12.8 versions. Drivers are backwards compatible, so this only affects the compilers. You will still retain CUDA 13 efficiencies from your updated drivers. This will be updated as dependencies are upgraded.

### Key Technical Features
* **Architecture Support:** Native **sm_120 (Compute Capability 12.0)** optimization via `TORCH_CUDA_ARCH_LIST` for Blackwell Tensor cores.
* **Base Stack:** `nvidia/cuda:12.8.0-devel-ubuntu24.04` providing the necessary headers for the latest NVIDIA drivers.
* **Pre-Built CUDA Extensions:** Bypasses common `ModuleNotFoundError` and compilation crashes by pre-baking:
    * **o_voxel:** Manually built from the TRELLIS.2 source for high-speed sparse voxel processing.
    * **nvdiffrast:** Compiled with `--no-build-isolation` to ensure correct EGL/CUDA interop.
    * **CuMesh:** Fully integrated 3D mesh processing backend.
    * **spconv-cu126:** Utilizes the verified bridge version for CUDA 12.8 compatibility.
* **Environment Stability:** * Implements `COMFY_ENV_SKIP_BUILD` to prevent custom nodes from creating conflicting local virtual environments.
    * Enforces `PIP_BREAK_SYSTEM_PACKAGES` for clean global installation within the container.

## 🛠️ Installation & Usage

### 1. Requirements
* **Host OS:** Any (Tested on Ubuntu 25.10, but since it's a Docker image, it should work anywhere provided you have the appropriate python version and NVIDIA drivers).
* **Hardware:** NVIDIA RTX 50-Series GPU (Tested with a 5070ti 16GB).
* **Software:** Docker + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

### 2. Build and Launch
```bash
# Clone this repository
git clone https://github.com/banjahman/ComfyUI-Docker-Trellis-CUDA
cd ComfyUI-Trellis2-Blackwell-Docker

# Initial build (Takes ~10-20 minutes for CUDA compilation)
# Go grab a coffee
docker-compose up -d --build

# Check logs 
docker logs -f comfyui-cuda13
```

### Notes on VRAM configuration
This is configured with the `--normalvram` flag enabled, but you can swap this to `--lowvram` if you run into OOM issues, or have a card with less available memory. Additionally, you can run this with `--highvram` if you're running on high end hardware.

See the `environment > CLI_ARGS` options in `docker-compose.yml`
