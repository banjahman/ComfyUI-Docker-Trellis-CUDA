\# ComfyUI-Trellis2-Blackwell-Docker

A high-performance, containerized ComfyUI environment specifically engineered for **NVIDIA Blackwell (RTX 50-Series)** GPUs. This build solves the complex compilation requirements for **TRELLIS 2** and other 3D generative nodes on latest-gen hardware.

\## 🚀 Optimized for RTX 5070 Ti / 5080 / 5090
This configuration is the result of intensive debugging to align CUDA 12.8, Python 3.12+, and the Blackwell architecture. It bakes heavy CUDA kernels directly into the image layers to ensure "instant-on" performance and runtime stability. 

This was developed with driver version 590.48.01 (CUDA 13.1). At the time of creation, dependencies haven't fully implemented CUDA 13, so it is compiled against the 12.8 versions for stability. Drivers are backwards compatible, ensuring you still retain Blackwell hardware efficiencies from your host drivers.

\### Key Technical Features
* **Architecture Support:** Native **sm_120 (Compute Capability 12.0)** optimization via \`TORCH_CUDA_ARCH_LIST\` for Blackwell Tensor cores.
* **Flash Attention 2.8+:** Custom-built from source within the container to enable high-speed attention kernels on Blackwell hardware.
* **Tiled Sparse Engine:** Includes \`FlexGEMM\` and the \`visualbruno\` fork of \`o_voxel\` to support high-resolution mesh generation (1024³+) on consumer VRAM.
* **Base Stack:** \`nvidia/cuda:12.8.0-devel-ubuntu24.04\` providing the necessary headers for the latest NVIDIA drivers.
* **Pre-Built CUDA Extensions:** Bypasses common \`ModuleNotFoundError\` and compilation crashes by pre-baking:
    * **o_voxel:** Built from the Visualbruno fork for tiled conversion support.
    * **nvdiffrast:** Compiled with \`--no-build-isolation\` to ensure correct EGL/CUDA interop.
    * **CuMesh:** Fully integrated 3D mesh processing backend.
    * **spconv-cu126:** Utilizes the verified bridge version for CUDA 12.8 compatibility.
* **Environment Stability:** * Implements \`COMFY_ENV_SKIP_BUILD\` to prevent custom nodes from creating conflicting local virtual environments.
    * Enforces \`PIP_BREAK_SYSTEM_PACKAGES\` for clean global installation within the container.

---

\## 🛠️ Installation & Usage

\### 1. Requirements
* **Host OS:** Any (Tested on Ubuntu 25.10; should work anywhere with appropriate NVIDIA drivers).
* **Hardware:** NVIDIA RTX 50-Series GPU (Tested with a 5070 Ti 16GB). 
* **Memory:** **64GB System RAM recommended** for the initial build phase.
* **Software:** Docker + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

\### 2. High-Speed Model Setup (Recommended)
Since the model files are large (~15GB), they are not included in the image. You can either provide them manually or let the container download them. To avoid Hugging Face throttling:

1. Create a \`.env\` file in the root directory:
   \`\`\`bash
   cp .env.example .env
   \`\`\`
2. Generate a **Read** token at [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens).
3. Paste your token into the \`.env\` file: \`HF_TOKEN=hf_your_token_here\`.

\### 3. Build and Launch
> ⚠️ **IMPORTANT:** The initial build compiles Flash Attention and FlexGEMM for the Blackwell architecture. This process takes **20-40 minutes**. If your system has 64GB of RAM or less, ensure \`MAX_JOBS=2\` is set in the Dockerfile to prevent out-of-memory crashes during compilation.

\`\`\`bash
# Clone this repository
git clone https://github.com/banjahman/ComfyUI-Docker-Trellis-CUDA
cd ComfyUI-Trellis2-Blackwell-Docker

# Initial build
docker-compose up -d --build

# Check logs 
docker logs -f comfyui-cuda13
\`\`\`

\### Loading Trellis Model
The container includes an intelligent sync script that checks for models on boot:
* **Manual:** Place \`TRELLIS.2-4B\` files in \`./models/checkpoints/microsoft/TRELLIS.2-4B\`.
* **Auto:** If you provided an \`HF_TOKEN\`, the container will automatically pull the Trellis weights, DINOv3, and Rembg models at maximum speed.

\### Notes on VRAM configuration
This is configured with the \`--normalvram\` flag enabled. You can swap this to \`--lowvram\` in the \`docker-compose.yml\` if you run into OOM issues during 3D extraction.

---

\## 📂 Repository Structure
\`\`\`text
.
├── models/             # Volume: Checkpoints, DinoV3, and U2Net weights
├── custom_nodes/       # Volume: Persistent nodes library
├── .env                # Your private HF_TOKEN
├── Dockerfile          # Blackwell-optimized build (sm_120)
└── entrypoint.sh       # Auto-downloader & environment warm-up
\`\`\`

\## ⚠️ Known Issues & Troubleshooting
* **First Prompt Lag:** The first generation may "hang" for ~60s while the GPU JIT-compiles the Triton kernels. This only happens once.
* **Trellis Node Error:** If you see "Value not in list," manually re-select the model in the ComfyUI dropdown and save your workflow.

---

\## 🤝 Credits & Acknowledgments
This project was built upon the collective efforts of the AI 3D community:

* **[PixelArtistry](https://www.youtube.com/@PixelArtistry_):** A massive shoutout for their incredible Trellis 2 guides and community workflows which served as the foundation for this environment.
* **[visualbruno](https://github.com/visualbruno):** For the Trellis 2 ComfyUI wrapper and essential 3D extensions.
* **Microsoft Research:** For the original [TRELLIS](https://github.com/microsoft/TRELLIS.2) architecture.
