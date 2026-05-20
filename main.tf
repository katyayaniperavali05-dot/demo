terraform {
  required_version = ">= 1.2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

variable "location" {
  description = "Azure region for the infrastructure."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group to create."
  type        = string
  default     = "demo-infra-rg"
}

variable "admin_object_id" {
  description = "Azure AD object ID for the admin principal (user or group)."
  type        = string
}

variable "developer_object_id" {
  description = "Azure AD object ID for the developer principal (user or group)."
  type        = string
}

resource "azurerm_resource_group" "infra" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "infra_vnet" {
  name                = "demo-infra-vnet"
  location            = azurerm_resource_group.infra.location
  resource_group_name = azurerm_resource_group.infra.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "infra_subnet" {
  name                 = "demo-infra-subnet"
  resource_group_name  = azurerm_resource_group.infra.name
  virtual_network_name = azurerm_virtual_network.infra_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_storage_account" "infra_storage" {
  name                     = "demoinfrastorage${random_id.sa_suffix.hex}"
  resource_group_name      = azurerm_resource_group.infra.name
  location                 = azurerm_resource_group.infra.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  identity {
    type = "SystemAssigned"
  }
}

resource "random_id" "sa_suffix" {
  byte_length = 4
}

resource "azurerm_role_assignment" "admin_assignment" {
  scope                = azurerm_resource_group.infra.id
  role_definition_name = "Owner"
  principal_id         = var.admin_object_id
  principal_type       = "User"
}

resource "azurerm_role_assignment" "developer_assignment" {
  scope                = azurerm_resource_group.infra.id
  role_definition_name = "Contributor"
  principal_id         = var.developer_object_id
  principal_type       = "User"
}

output "resource_group_name" {
  description = "Name of the Azure resource group created for this infrastructure."
  value       = azurerm_resource_group.infra.name
}

output "resource_group_id" {
  description = "ID of the Azure resource group created for the infrastructure."
  value       = azurerm_resource_group.infra.id
}

output "admin_role_assignment_id" {
  description = "Role assignment ID for the admin principal."
  value       = azurerm_role_assignment.admin_assignment.id
}

output "developer_role_assignment_id" {
  description = "Role assignment ID for the developer principal."
  value       = azurerm_role_assignment.developer_assignment.id
}
