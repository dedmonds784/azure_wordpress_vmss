resource "azurerm_linux_virtual_machine_scale_set" "wordpress" {
  name                            = "${var.client_tag}-vmscaleset-${var.environment_prefix}"
  location                        = data.azurerm_resource_group.client_resource_group.location
  resource_group_name             = local.environment_resource_group
  sku                             = "Standard_DS2_v2"
  instances                       = 3
  admin_username                  = "${var.client_tag}wordpressvm"
  admin_password                  = random_password.vmpassword.result
  disable_password_authentication = false
  custom_data                     = data.template_cloudinit_config.config.rendered

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.client_tag}NetworkInterface${var.environment_prefix}"
    primary = true

    ip_configuration {
      name      = "${var.client_tag}IPConfiguration${var.environment_prefix}"
      subnet_id = azurerm_subnet.wordpress_subnet_backend.id
      application_gateway_backend_address_pool_ids = tolist([
        tolist(azurerm_application_gateway.wordpress_application_gateway.backend_address_pool).0.id,
      ])
      primary = true
    }
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  tags = tomap({
    client = var.client_tag
  })
}

data "template_file" "script" {
  template = file("${path.module}/cloud-init.tpl")
  vars = {
    "database_fqdn"                  = "${azurerm_mysql_server.wordpress_database_server.fqdn}"
    "wordpress_storage_account_name" = "${azurerm_storage_account.wordpress_storage_account.name}"
    "client_tag"                     = "${var.client_tag}"
    "environment_prefix"             = "${var.environment_prefix}"
    "database_password"              = "${random_password.dbpassword.result}"
    "database_user"                  = "${var.client_tag}wp"
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.script.rendered

  }
}

output "cloud_init" {
  value = data.template_file.script.rendered
}