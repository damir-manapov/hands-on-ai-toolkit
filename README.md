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
├── terraform/
│   ├── check.sh
│   ├── cloud-init/
│   │   └── selectel/
│   │       └── ai-toolkit.yaml.tftpl
│   └── selectel/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars.example
│       ├── terraform.tfvars.moscow-4090
│       └── terraform.tfvars.moscow-6000ada
├── config/
│   └── examples/
│       └── train_lora_flux_24gb.yml
├── datasets/
├── output/
├── lib.sh              # shared helpers for provision/destroy
├── provision.sh        # one-command Selectel provisioning
├── destroy.sh          # one-command teardown
├── check.sh            # runtime sanity checks
├── all-checks.sh       # all checks in one go
├── health.sh           # gitleaks + renovate freshness
├── security.sh         # gitleaks secret scan
├── renovate-check.sh   # Docker/Terraform dep freshness
└── renovate.json
```

## Useful Checks

```sh
./check.sh           # Local runtime sanity checks + compose config validation
./terraform/check.sh # Terraform fmt -check / validate (+ optional tflint/trivy)
./security.sh        # gitleaks secret scan (optional strict mode)
./renovate-check.sh  # Checks Docker/Terraform updates via Renovate dry-run
./all-checks.sh      # Runs runtime + terraform + security + renovate checks
./health.sh          # gitleaks + renovate (standard health pattern)
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

## Selectel GPU Server

### Quick start

```sh
# 1. Export Selectel credentials
export TF_VAR_selectel_domain="..."
export TF_VAR_selectel_username="..."
export TF_VAR_selectel_password="..."
export TF_VAR_selectel_openstack_password="..."
# optional
export TF_VAR_ai_toolkit_auth="super-secure-token"
export TF_VAR_hf_token="hf_..."

# 2. Provision (Moscow RTX 4090 preset by default)
./provision.sh
# Or use RTX 6000 Ada (48GB VRAM) for larger models
./provision.sh terraform.tfvars.moscow-6000ada

# 3. Destroy when done
./destroy.sh
```

### Scripts

| Script | Purpose |
|--------|---------|
| `./provision.sh` | Init + plan + apply, wait for cloud-init, verify GPU & UI |
| `./destroy.sh` | Destroy all infrastructure (with confirmation prompt) |

Both default to the `terraform.tfvars.moscow-4090` preset. Pass a custom var file:

```sh
./provision.sh terraform.tfvars.moscow-6000ada
./destroy.sh terraform.tfvars.moscow-6000ada
```

Skip destroy confirmation: `FORCE=1 ./destroy.sh`

### Presets

| Preset | GPU | vCPU | RAM | VRAM | Flavor |
|--------|-----|------|-----|------|--------|
| `terraform.tfvars.moscow-4090` (default) | RTX 4090 | 8 | 32 GB | 24 GB | `GL10.8-32768-0-1GPU` |
| `terraform.tfvars.moscow-6000ada` | RTX 6000 Ada | 12 | 64 GB | 48 GB | `GL14.12-65536-1GPU` |

### Manual terraform (if needed)

```sh
cd terraform/selectel
terraform init
terraform plan  -var-file=terraform.tfvars.moscow-4090
terraform apply -var-file=terraform.tfvars.moscow-4090
terraform output ssh_command
terraform output ui_url
terraform destroy -var-file=terraform.tfvars.moscow-4090
```
