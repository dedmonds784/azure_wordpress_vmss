resource "azurerm_virtual_network" "wordpress_vnet" {
  name                = "${var.client_tag}-wordpress-vnet-${var.environment_prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.client_resource_group.location
  resource_group_name = local.environment_resource_group

  tags = tomap({
    client = var.client_tag
  })
}

resource "azurerm_subnet" "wordpress_subnet_backend" {
  name                 = "${var.client_tag}-backend-subnet-${var.environment_prefix}"
  resource_group_name  = local.environment_resource_group
  virtual_network_name = azurerm_virtual_network.wordpress_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  private_endpoint_network_policies_enabled = false
  service_endpoints = [
    "Microsoft.Sql", "Microsoft.Storage"
  ]
}

resource "azurerm_subnet" "wordpress_subnet_frontend" {
  name                 = "${var.client_tag}-frontend-subnet-${var.environment_prefix}"
  resource_group_name  = local.environment_resource_group
  virtual_network_name = azurerm_virtual_network.wordpress_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "wordpress_public_ip" {
  name                = "${var.client_tag}-wordpress-public-ip-${var.environment_prefix}"
  location            = data.azurerm_resource_group.client_resource_group.location
  resource_group_name = local.environment_resource_group
  allocation_method   = "Static"
  domain_name_label   = random_string.fqdn.result
  sku                 = "Standard"
  zones               = tolist([1, 2, 3])
  tags = tomap({
    client = var.client_tag
  })
}

resource "azurerm_application_gateway" "wordpress_application_gateway" {
  name                = "${var.client_tag}-appgateway-${var.environment_prefix}"
  resource_group_name = local.environment_resource_group
  location            = data.azurerm_resource_group.client_resource_group.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 3
  }

  zones = tolist([1, 2, 3])

  gateway_ip_configuration {
    name      = "${var.client_tag}-gateway-ip-${var.environment_prefix}"
    subnet_id = azurerm_subnet.wordpress_subnet_frontend.id
  }

  frontend_port {
    name = "${var.client_tag}-feport-${var.environment_prefix}"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${var.client_tag}-feip-${var.environment_prefix}"
    public_ip_address_id = azurerm_public_ip.wordpress_public_ip.id
  }

  backend_address_pool {
    name = "${var.client_tag}-beap-${var.environment_prefix}"
  }

  backend_http_settings {
    name                  = "${var.client_tag}-be-htst-${var.environment_prefix}"
    cookie_based_affinity = "Enabled"
    port                  = 80
    protocol              = "Http"
  }

  http_listener {
    name                           = "${var.client_tag}-httplstn-${var.environment_prefix}"
    frontend_ip_configuration_name = "${var.client_tag}-feip-${var.environment_prefix}"
    frontend_port_name             = "${var.client_tag}-feport-${var.environment_prefix}"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${var.client_tag}-rqrt-${var.environment_prefix}"
    rule_type                  = "Basic"
    http_listener_name         = "${var.client_tag}-httplstn-${var.environment_prefix}"
    backend_address_pool_name  = "${var.client_tag}-beap-${var.environment_prefix}"
    backend_http_settings_name = "${var.client_tag}-be-htst-${var.environment_prefix}"
    priority                   = 1
  }
}