
resource "azurerm_storage_account" "wordpress_storage_account" {
  name                = "${var.client_tag}wpstorage${var.environment_prefix}"
  resource_group_name = local.environment_resource_group

  location                 = data.azurerm_resource_group.client_resource_group.location
  account_tier             = "Premium"
  account_replication_type = "ZRS"
  account_kind             = "FileStorage"

  enable_https_traffic_only = false

  tags = tomap({
    client = var.client_tag
  })
}

resource "azurerm_storage_share" "wordpress_nfs" {
  name                 = "${var.client_tag}wpstorageshare${var.environment_prefix}"
  storage_account_name = azurerm_storage_account.wordpress_storage_account.name
  enabled_protocol     = "NFS"
  quota                = 1024
}

resource "azurerm_private_dns_zone" "wordpress_storage_private_dns_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = local.environment_resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "wordpress_storage_private_dns_zone_link" {
  name                  = "${var.client_tag}-network-link-${var.environment_prefix}"
  resource_group_name   = local.environment_resource_group
  private_dns_zone_name = azurerm_private_dns_zone.wordpress_storage_private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.wordpress_vnet.id
}

resource "azurerm_private_endpoint" "wordpress_storage_private_endpoint" {
  name                = "${var.client_tag}-storage-endpoint-${var.environment_prefix}"
  location            = data.azurerm_resource_group.client_resource_group.location
  resource_group_name = local.environment_resource_group
  subnet_id           = azurerm_subnet.wordpress_subnet_backend.id

  private_service_connection {
    name                           = "${var.client_tag}-${var.environment_prefix}-privateserviceconnection-storage"
    private_connection_resource_id = azurerm_storage_account.wordpress_storage_account.id
    is_manual_connection           = false
    subresource_names = ["file"]
  }
}