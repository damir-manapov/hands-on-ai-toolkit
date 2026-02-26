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
│   ├── cloud-init/
│   │   └── selectel/
│   │       └── ai-toolkit.yaml.tftpl
│   └── selectel/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── config/
│   └── examples/
│       └── train_lora_flux_24gb.yml
├── datasets/
├── output/
├── check.sh
└── all-checks.sh
```

## Useful Checks

```sh
./check.sh      # Local runtime sanity checks + compose config validation
./terraform/check.sh # Terraform fmt/validate (+ optional tflint/trivy)
./security.sh   # gitleaks secret scan (optional strict mode)
./renovate-check.sh # Checks Docker/Terraform updates via Renovate dry-run
./all-checks.sh # Runs runtime + terraform + security + renovate checks
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

## Provision server in Selectel (similar to optina-optimisations)

1. Prepare variables:
	```sh
	cd terraform/selectel
	cp terraform.tfvars.example terraform.tfvars
	```

2. Export Selectel credentials:
	```sh
	export TF_VAR_selectel_domain="..."
	export TF_VAR_selectel_username="..."
	export TF_VAR_selectel_password="..."
	export TF_VAR_selectel_openstack_password="..."
	# optional
	export TF_VAR_ai_toolkit_auth="super-secure-token"
	```

3. Create server:
	```sh
	terraform init
	terraform apply
	```

4. Get access details:
	```sh
	terraform output ssh_command
	terraform output ui_url
	terraform output wait_for_ready
	```

5. Destroy when done:
	```sh
	terraform destroy
	```
