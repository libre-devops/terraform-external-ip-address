output "is_linux" {
  description = "True if the OS is Linux"
  value       = local.is_linux
}

output "is_windows" {
  description = "True if the OS is Windows"
  value       = local.is_windows
}

output "os" {
  description = "The OS that is running the commands"
  value       = local.os
}

output "private_ip_address" {
  description = "The private IP address of caller"
  value       = local.private_ip
}

output "public_ip_address" {
  description = "The public IP address of caller"
  value       = local.public_ip
}
