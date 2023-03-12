variable "location_id" {
  description = "Where the region where the clients resources in Azure should be created."
  default     = "East US"
}

variable "application_port" {
  description = "The port that you want to expose to the external load balancer"
  default     = 80
}

variable "client_resource_group" {
  description = "name of the resource group that should be associated with that clients resources."
}

variable "client_name" {
  default = "name of the client the resources are being created"
}

variable "environment_prefix" {
  default = "the environment classification for where to build the wordpress resources"
}

variable "client_tag" {
  default = "values to set for tags on resources"
}