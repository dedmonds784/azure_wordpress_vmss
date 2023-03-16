resource "azurerm_key_vault" "wordpress_keyvault" {
  name                        = "kv-${var.client_tag}-wp-${var.environment_prefix}"
  location                    = data.azurerm_resource_group.client_resource_group.location
  resource_group_name         = local.environment_resource_group
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Get",
    ]
    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
    ]
    storage_permissions = [
      "Get",
    ]
  }
}

resource "random_password" "vmpassword" {
  length  = 16
  special = true
}

resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "${var.client_tag}wordpressvmpassword${var.environment_prefix}"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.wordpress_keyvault.id
  depends_on   = [azurerm_key_vault.wordpress_keyvault]
}

resource "random_password" "dbpassword" {
  length  = 16
  special = true
}

resource "azurerm_key_vault_secret" "dbpassword" {
  name         = "${var.client_tag}wordpressdatabasepassword${var.environment_prefix}"
  value        = random_password.dbpassword.result
  key_vault_id = azurerm_key_vault.wordpress_keyvault.id
  depends_on   = [azurerm_key_vault.wordpress_keyvault]
}
