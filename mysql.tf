# Create MySQL Server
resource "azurerm_mysql_server" "wordpress_database_server" {
  resource_group_name = local.environment_resource_group
  name                = "${var.client_tag}-wordpress-mysql-server-${var.environment_prefix}"
  location            = data.azurerm_resource_group.client_resource_group.location
  version             = "5.7"

  administrator_login          = "${var.client_tag}wp"
  administrator_login_password = random_password.dbpassword.result

  sku_name                     = "GP_Gen5_2"
  storage_mb                   = "5120"
  auto_grow_enabled            = false
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = false
  ssl_minimal_tls_version_enforced  = "TLSEnforcementDisabled"
}

# Create MySql DataBase
resource "azurerm_mysql_database" "wordpress_database" {
  name                = "wordpressdb"
  resource_group_name = local.environment_resource_group
  server_name         = azurerm_mysql_server.wordpress_database_server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# Config MySQL Server Firewall Rule
resource "azurerm_mysql_firewall_rule" "wordpress" {
  name                = "${var.client_tag}-wordpress-mysql-firewall-rule-${var.environment_prefix}"
  resource_group_name = local.environment_resource_group
  server_name         = azurerm_mysql_server.wordpress_database_server.name
  start_ip_address    = azurerm_public_ip.wordpress_public_ip.ip_address
  end_ip_address      = azurerm_public_ip.wordpress_public_ip.ip_address
}

data "azurerm_mysql_server" "wordpress" {
  name                = azurerm_mysql_server.wordpress_database_server.name
  resource_group_name = local.environment_resource_group
}

resource "azurerm_private_dns_zone" "wordpress_database_private_dns_zone" {
  name                = "privatelink.mysql.database.azure.net"
  resource_group_name = local.environment_resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "wordpress_database_private_dns_zone_link" {
  name                  = "${var.client_tag}-network-link-${var.environment_prefix}"
  resource_group_name   = local.environment_resource_group
  private_dns_zone_name = azurerm_private_dns_zone.wordpress_database_private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.wordpress_vnet.id
}

resource "azurerm_private_endpoint" "wordpress_database_private_endpoint" {
  name                = "${var.client_tag}-mysql-endpoint-${var.environment_prefix}"
  location            = data.azurerm_resource_group.client_resource_group.location
  resource_group_name = local.environment_resource_group
  subnet_id           = azurerm_subnet.wordpress_subnet_backend.id

  private_service_connection {
    name                           = "${var.client_tag}-${var.environment_prefix}-privateserviceconnection-mysql"
    private_connection_resource_id = azurerm_mysql_server.wordpress_database_server.id
    is_manual_connection           = false
    subresource_names = ["mysqlServer"]
  }
}