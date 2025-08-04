variable "resource_group_name" {
  default = "WebApp_ResourceGroup"
}

variable "location" {
  default = "germanywestcentral"
}

variable "vnet_name" {
  default = "vnet-webapp"
}

variable "app_service_plan_name" {
  default = "appservice-plan"
}

variable "web_app_name" {
  default = "fl-frontend-webapp"
}

variable "vm_name" {
  default = "fl-backend-vm"
}

variable "storage_account_name" {
  default = "flwebappstorage"
}

variable "storage_container_name" {
  default = "flwebappcontainer"
}

variable "user_object_id" {
  description = "The Object ID of the Terraform user"
  type        = string
  sensitive   = true
}