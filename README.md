# Hands-On AI Toolkit

Minimal runtime wrapper for [AI Toolkit by Ostris](https://github.com/ostris/ai-toolkit) using Docker Compose.

## Prerequisites

- Docker & Docker Compose
- Hugging Face token (for gated models, optional depending on model)
- NVIDIA GPU + NVIDIA Container Toolkit (required for real training workloads)

## Project Layout

```
├── compose/
│   └── docker-compose.yml
├── config/
│   └── examples/
│       └── train_lora_flux_24gb.yml
├── datasets/
├── output/
├── aitk_db.db
├── check.sh
├── health.sh
└── all-checks.sh
```

## Useful Checks

```sh
./check.sh      # Local runtime sanity checks + compose config validation
./all-checks.sh # Wrapper for check.sh
```

## Run (when internet is available)

```sh
docker compose -f compose/docker-compose.yml pull
docker compose -f compose/docker-compose.yml up -d
```

UI endpoint: `http://localhost:8675`

Stop:

```sh
docker compose -f compose/docker-compose.yml down
```
