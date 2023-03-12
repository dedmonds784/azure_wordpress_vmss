

output "application_public_address" {
  value = azurerm_public_ip.wordpress_public_ip.fqdn
}

output "vm_admin_username" {
  value = "${local.client_tag}wordpressvm"
}

output "database_admin_username" {
  value = "${local.client_tag}wordpressdb"
}