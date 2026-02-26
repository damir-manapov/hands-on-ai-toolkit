output "project_id" {
  description = "Selectel project ID"
  value       = selectel_vpc_project_v2.ai_toolkit.id
}

output "server_ip" {
  description = "Public IP of AI Toolkit server"
  value       = openstack_networking_floatingip_v2.ai_toolkit.address
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh root@${openstack_networking_floatingip_v2.ai_toolkit.address}"
}

output "ui_url" {
  description = "AI Toolkit web UI URL"
  value       = "http://${openstack_networking_floatingip_v2.ai_toolkit.address}:8675"
}

output "wait_for_ready" {
  description = "Wait until cloud-init startup script is finished"
  value       = "ssh root@${openstack_networking_floatingip_v2.ai_toolkit.address} 'while [ ! -f /root/cloud-init-ready ]; do echo \"Waiting for setup...\"; sleep 10; done; echo \"Ready!\"'"
}
