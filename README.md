# Hands-On AI Toolkit

A hands-on project for learning [AI Toolkit by Ostris](https://github.com/ostris/ai-toolkit) — LoRA training for diffusion models (FLUX, SDXL, Wan, etc.) on consumer GPUs.

## Architecture

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│   Dataset    │────▶│   AI Toolkit     │────▶│    Output    │
│ (images+txt) │     │  (GPU Training)  │     │  (LoRA .safetensors) │
└──────────────┘     └──────────────────┘     └──────────────┘
                            │
                     ┌──────┴──────┐
                     │  Web UI     │
                     │ :8675       │
                     └─────────────┘
```

**Components:**
- **AI Toolkit** — All-in-one training suite for diffusion models (LoRA, LoKr, full finetune)
- **Web UI** — Browser interface for starting/stopping/monitoring training jobs
- **Docker + NVIDIA GPU** — Containerized training with CUDA support

## Prerequisites

- Docker & Docker Compose
- NVIDIA GPU with 24GB+ VRAM (for FLUX training)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- Node.js 22+
- pnpm 10+
- gitleaks (for security checks)
- Hugging Face account + token (for gated models like FLUX.1-dev)

## Getting Started

1. Install dependencies:
   ```sh
   pnpm install
   ```

2. Create `.env` file with your HF token:
   ```sh
   echo "HF_TOKEN=your_hf_token_here" > .env
   ```

3. Pull Docker images:
   ```sh
   pnpm run compose:pull
   ```

4. Start AI Toolkit:
   ```sh
   pnpm run compose:up
   ```

5. Open the UI at `http://localhost:8675`

6. Run tests:
   ```sh
   pnpm test
   ```

7. Stop services:
   ```sh
   pnpm run compose:down
   ```

8. Reset (remove volumes):
   ```sh
   pnpm run compose:reset
   ```

## Services Endpoints

| Service     | Port | URL                     |
|-------------|------|-------------------------|
| AI Toolkit  | 8675 | `http://localhost:8675`  |

## Project Structure

```
├── compose/
│   ├── docker-compose.yml   # Docker Compose configuration
│   └── ai-toolkit/
│       └── Dockerfile       # GPU-enabled AI Toolkit image
├── config/
│   └── examples/
│       └── train_lora_flux_24gb.yml  # Example FLUX LoRA training config
├── docs/                    # Documentation
├── src/
│   ├── client.ts            # AI Toolkit HTTP client
│   └── index.ts             # Main exports
└── tests/
    └── toolkit.test.ts      # AI Toolkit integration tests
```

## Training

1. Copy an example config:
   ```sh
   cp config/examples/train_lora_flux_24gb.yml config/my_training.yml
   ```

2. Edit the config (dataset path, trigger word, steps, etc.)

3. Start training via the UI at `http://localhost:8675` or mount the config into the container

## Development

Run checks:
```sh
./check.sh      # Format, lint, typecheck, test
./health.sh     # Security scan, dependency audit
./all-checks.sh # Run both
```
