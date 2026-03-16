# ComfyUI-Trellis2-Blackwell-Docker

A high-performance, containerized ComfyUI environment specifically engineered for **NVIDIA Blackwell (RTX 50-Series)** GPUs. This build solves the complex compilation requirements for **TRELLIS 2** and other 3D generative nodes on latest-gen hardware.

## 🚀 Optimized for RTX 5070 Ti / 5080 / 5090
This configuration is the result of intensive debugging to align CUDA 12.8, Python 3.12+, and the Blackwell architecture. It bakes heavy CUDA kernels directly into the image layers to ensure "instant-on" performance and runtime stability. 

**Note on Driver Compatibility:** Developed with driver 590.48.01 (CUDA 13.1). While compiled against CUDA 12.8 for library stability, it utilizes the sm_120 architecture to leverage Blackwell's specific hardware efficiencies.

### Key Technical Features
* **Architecture Support:** Native **sm_120 (Compute Capability 12.0)** optimization via `TORCH_CUDA_ARCH_LIST`.
* **Flash Attention 2.8+:** Custom-built from source to support Blackwell Tensor Cores.
* **Tiled Sparse Engine:** Includes `FlexGEMM` and the `visualbruno` fork of `o_voxel` for high-resolution (1024³+) mesh generation on consumer VRAM.
* **Pre-Built CUDA Extensions:** Bypasses `ModuleNotFoundError` by pre-baking `CuMesh`, `nvdiffrast`, and `spconv-cu126`.

---

## 🛠️ Installation & Usage

### 1. Requirements
* **Hardware:** NVIDIA RTX 50-Series GPU (Tested with 5070 Ti 16GB).
* **Software:** Docker + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).
* **Memory:** At least 32GB System RAM (64GB recommended) for the initial compilation.

### 2. Setup Credentials & Models
1. **Environment:** `cp .env.example .env` and add your `HF_TOKEN`.
2. **Models:** The container will auto-download ~15GB of weights on first boot if not found in `./models`.
   * **Trellis:** `models/checkpoints/microsoft/TRELLIS.2-4B`
   * **DinoV3:** `models/facebook/dinov3-vitl16-pretrain-lvd1689m`

### 3. Build and Launch
> ⚠️ **IMPORTANT:** The initial build includes compiling Flash Attention and FlexGEMM for Blackwell. This process takes **20-40 minutes** depending on your CPU. It is highly recommended to set `MAX_JOBS=2` in the Dockerfile if you have 64GB of RAM or less to prevent system crashes.

```bash
docker-compose up -d --build
docker logs -f comfyui-cuda13
