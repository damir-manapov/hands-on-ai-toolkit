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
│       └── terraform.tfvars.moscow-4080
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

# 2. Provision (Moscow RTX 4090 preset by default)
./provision.sh

# 3. Destroy when done
./destroy.sh
```

### Scripts

| Script | Purpose |
|--------|---------|
| `./provision.sh` | Init + plan + apply, wait for cloud-init, verify GPU & UI |
| `./destroy.sh` | Destroy all infrastructure (with confirmation prompt) |

Both default to the `terraform.tfvars.moscow-4080` preset. Pass a custom var file:

```sh
./provision.sh my-custom.tfvars
./destroy.sh my-custom.tfvars
```

Skip destroy confirmation: `FORCE=1 ./destroy.sh`

### Manual terraform (if needed)

```sh
cd terraform/selectel
terraform init
terraform plan  -var-file=terraform.tfvars.moscow-4080
terraform apply -var-file=terraform.tfvars.moscow-4080
terraform output ssh_command
terraform output ui_url
terraform destroy -var-file=terraform.tfvars.moscow-4080
```
