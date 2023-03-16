terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.46.0"
    }
  }
}

data "azurerm_resource_group" "client_resource_group" {
  name = local.environment_resource_group
}

data "azurerm_client_config" "current" {
}

resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  numeric = false
}

locals {
  client_tag                 = lower(trimspace(var.client_name))
  environment_resource_group = "${var.client_resource_group}-${var.environment_prefix}"
}
