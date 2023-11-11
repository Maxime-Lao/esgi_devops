# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Main resource group
resource "azurerm_resource_group" "rg_main" {
  name     = var.resource_group
  location = var.location
  tags = {
    environment = "DevOps ESGI"
  }
}

#container registry
resource "azurerm_container_registry" "acr" {
  name                     = var.acr_name
  resource_group_name      = azurerm_resource_group.rg_main.name
  location                 = var.location
  sku                      = "Standard"
  admin_enabled            = true
  tags = {
    environment = "DevOps ESGI"
  }
}

#cluster kubernetes
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_main.name
  dns_prefix          = "dnsmuthulanmaxime"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  tags = {
    environment = "DevOps ESGI"
  }

  identity {
    type = "SystemAssigned"
  }
}

#ip adress
resource "azurerm_public_ip" "ip" {
  name                = var.ip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_main.name
  allocation_method   = "Static"
  tags = {
    environment = "DevOps ESGI"
  }
}

#role assignment
resource "azurerm_role_assignment" "acr_role" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "user_role" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.user_object_id
}

#output
output "ip" {
  value = azurerm_public_ip.ip.ip_address
}
