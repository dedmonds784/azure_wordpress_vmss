locals {
  client = csvdecode(file("websites.csv"))
}

module "client_wordpress_app" {
  for_each = { for client in local.client : client.client_name => client }
  source   = "../modules/azure_wordpress"

  location_id           = each.value.location_id
  application_port      = 80
  client_resource_group = each.value.resource_group
  client_name           = each.value.client_name
  environment_prefix    = dev
  client_tag            = each.value.client_tag
}