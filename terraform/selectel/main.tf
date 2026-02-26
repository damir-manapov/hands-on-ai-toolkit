terraform {
  required_version = ">= 1.0"

  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "7.5.4"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "3.4.0"
    }
  }
}

provider "selectel" {
  domain_name = var.selectel_domain
  username    = var.selectel_username
  password    = var.selectel_password
  auth_region = var.region
  auth_url    = "https://cloud.api.selcloud.ru/identity/v3/"
}

resource "selectel_vpc_project_v2" "ai_toolkit" {
  name = "ai-toolkit-${var.environment_name}"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}

resource "selectel_iam_serviceuser_v1" "ai_toolkit" {
  name     = "ai-toolkit-${var.environment_name}"
  password = var.selectel_openstack_password

  role {
    role_name  = "member"
    scope      = "project"
    project_id = selectel_vpc_project_v2.ai_toolkit.id
  }
}

resource "selectel_vpc_keypair_v2" "ai_toolkit" {
  name       = "ai-toolkit-key"
  public_key = file(var.ssh_public_key_path)
  user_id    = selectel_iam_serviceuser_v1.ai_toolkit.id
}

provider "openstack" {
  auth_url    = "https://cloud.api.selcloud.ru/identity/v3"
  domain_name = var.selectel_domain
  tenant_id   = selectel_vpc_project_v2.ai_toolkit.id
  user_name   = selectel_iam_serviceuser_v1.ai_toolkit.name
  password    = var.selectel_openstack_password
  region      = var.region
}

data "openstack_images_image_v2" "ubuntu" {
  name        = var.image_name
  most_recent = true

  depends_on = [
    selectel_vpc_project_v2.ai_toolkit,
    selectel_iam_serviceuser_v1.ai_toolkit,
  ]
}

data "openstack_compute_flavor_v2" "ai_toolkit" {
  count = var.flavor_name != "" ? 1 : 0
  name  = var.flavor_name

  depends_on = [
    selectel_vpc_project_v2.ai_toolkit,
    selectel_iam_serviceuser_v1.ai_toolkit,
  ]
}

resource "openstack_compute_flavor_v2" "ai_toolkit" {
  count     = var.flavor_name == "" ? 1 : 0
  name      = "ai-toolkit-${var.environment_name}-${var.cpu_count}vcpu-${var.ram_gb}gb"
  vcpus     = var.cpu_count
  ram       = var.ram_gb * 1024
  disk      = 0
  is_public = false

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    selectel_vpc_project_v2.ai_toolkit,
    selectel_iam_serviceuser_v1.ai_toolkit,
  ]
}

resource "openstack_networking_network_v2" "ai_toolkit" {
  name = "ai-toolkit-network"

  depends_on = [
    selectel_vpc_project_v2.ai_toolkit,
    selectel_iam_serviceuser_v1.ai_toolkit,
  ]
}

resource "openstack_networking_subnet_v2" "ai_toolkit" {
  name            = "ai-toolkit-subnet"
  network_id      = openstack_networking_network_v2.ai_toolkit.id
  cidr            = "10.60.0.0/24"
  dns_nameservers = ["188.93.16.19", "188.93.17.19"]
}

data "openstack_networking_network_v2" "external" {
  external = true

  depends_on = [
    selectel_vpc_project_v2.ai_toolkit,
    selectel_iam_serviceuser_v1.ai_toolkit,
  ]
}

resource "openstack_networking_router_v2" "ai_toolkit" {
  name                = "ai-toolkit-router"
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "ai_toolkit" {
  router_id = openstack_networking_router_v2.ai_toolkit.id
  subnet_id = openstack_networking_subnet_v2.ai_toolkit.id
}

resource "openstack_networking_secgroup_v2" "ai_toolkit" {
  name        = "ai-toolkit-secgroup"
  description = "Security group for AI Toolkit VM"

  depends_on = [
    selectel_vpc_project_v2.ai_toolkit,
    selectel_iam_serviceuser_v1.ai_toolkit,
  ]
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.allowed_ssh_cidr
  security_group_id = openstack_networking_secgroup_v2.ai_toolkit.id
}

resource "openstack_networking_secgroup_rule_v2" "ui" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8675
  port_range_max    = 8675
  remote_ip_prefix  = var.allowed_ui_cidr
  security_group_id = openstack_networking_secgroup_v2.ai_toolkit.id
}

resource "openstack_networking_secgroup_rule_v2" "internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "10.60.0.0/24"
  security_group_id = openstack_networking_secgroup_v2.ai_toolkit.id
}

resource "openstack_blockstorage_volume_v3" "boot" {
  name              = "ai-toolkit-boot"
  size              = var.disk_size_gb
  image_id          = data.openstack_images_image_v2.ubuntu.id
  volume_type       = "${var.disk_type}.${var.availability_zone}"
  availability_zone = var.availability_zone
}

resource "openstack_networking_port_v2" "ai_toolkit" {
  name           = "ai-toolkit-port"
  network_id     = openstack_networking_network_v2.ai_toolkit.id
  admin_state_up = true

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.ai_toolkit.id
  }

  security_group_ids = [openstack_networking_secgroup_v2.ai_toolkit.id]

  depends_on = [
    selectel_vpc_project_v2.ai_toolkit,
    selectel_iam_serviceuser_v1.ai_toolkit,
  ]
}

resource "openstack_compute_instance_v2" "ai_toolkit" {
  name              = "ai-toolkit-${var.environment_name}"
  flavor_id         = var.flavor_name != "" ? data.openstack_compute_flavor_v2.ai_toolkit[0].id : openstack_compute_flavor_v2.ai_toolkit[0].id
  key_pair          = selectel_vpc_keypair_v2.ai_toolkit.name
  availability_zone = var.availability_zone
  user_data = templatefile("${path.module}/../cloud-init/selectel/ai-toolkit.yaml.tftpl", {
    ai_toolkit_auth = var.ai_toolkit_auth
  })

  network {
    port = openstack_networking_port_v2.ai_toolkit.id
  }

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.boot.id
    source_type           = "volume"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [image_id]
  }

  vendor_options {
    ignore_resize_confirmation = true
  }

  depends_on = [openstack_networking_router_interface_v2.ai_toolkit]
}

resource "openstack_networking_floatingip_v2" "ai_toolkit" {
  pool = "external-network"

  depends_on = [
    selectel_vpc_project_v2.ai_toolkit,
    selectel_iam_serviceuser_v1.ai_toolkit,
  ]
}

resource "openstack_networking_floatingip_associate_v2" "ai_toolkit" {
  floating_ip = openstack_networking_floatingip_v2.ai_toolkit.address
  port_id     = openstack_networking_port_v2.ai_toolkit.id

  depends_on = [openstack_networking_router_interface_v2.ai_toolkit]
}
