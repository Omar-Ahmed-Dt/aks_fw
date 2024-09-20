# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rg
  location = var.location
}

# User-Assigned Managed Identity for AKS
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${var.cluster_name}-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Virtual Network for AKS and Firewall
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.cluster_name}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for Azure Firewall
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Public IP for the Firewall
resource "azurerm_public_ip" "firewall_public_ip" {
  name                = "${var.cluster_name}-firewall-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Azure Firewall
resource "azurerm_firewall" "firewall" {
  name                = "${var.cluster_name}-firewall"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  
  ip_configuration {
    name                 = "firewall-ip-config"
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
    subnet_id            = azurerm_subnet.firewall_subnet.id
  }
}

# Route Table for AKS
resource "azurerm_route_table" "aks_route_table" {
  name                = "aks-route-table"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Route through Azure Firewall
resource "azurerm_route" "route_through_firewall" {
  name                   = "firewall-route"
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  route_table_name       = azurerm_route_table.aks_route_table.name
  resource_group_name    = azurerm_resource_group.rg.name
}

# Associate Route Table with AKS Subnet
resource "azurerm_subnet_route_table_association" "aks_route_table_assoc" {
  subnet_id      = azurerm_subnet.aks_subnet.id
  route_table_id = azurerm_route_table.aks_route_table.id
}

# Firewall Policy
resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "${var.cluster_name}-firewall-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

# Firewall Rule Collection for AKS
resource "azurerm_firewall_policy_rule_collection_group" "firewall_rule_collection" {
  name                = "firewall-rule-collection"
  firewall_policy_id  = azurerm_firewall_policy.firewall_policy.id
  priority            = 100

  # Network Rule Collection - Block specific IPs
  # network_rule_collection {
  #   name     = "block-specific-ips"
  #   priority = 100
  #   action   = "Deny"  # This will block traffic

  #   rule {
  #     name             = "block-specific-ip-rule"
  #     description      = "Block traffic from specific IPs"
  #     source_addresses = ["<BLOCKED_IP_1>", "<BLOCKED_IP_2>"]  # Add your specific IPs here
  #     destination_addresses = ["*"]  
  #     destination_ports = ["*"]  
  #     protocols        = ["TCP", "UDP"]
  #   }
  # }

  # Network Rule Collection - Allow DNS Traffic
  network_rule_collection {
    name     = "allow-dns"
    priority = 200
    action   = "Allow"

    rule {
      name             = "allow-dns-rule"
      description      = "Allow DNS traffic"
      source_addresses = ["*"]
      destination_addresses = ["*"]
      destination_ports = ["53"]
      protocols        = ["UDP", "TCP"]
    }
  }

  # Application Rule Collection - Allow HTTPS from *.poseidondev.website
  application_rule_collection {
    name     = "allow-https-from-domain"
    priority = 300
    action   = "Allow"

    rule {
      name = "allow-https-rule"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = ["*.poseidondev.website"]
    }
  }
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name
  node_resource_group = var.node_resource_group

  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = "Standard_D2pls_v5"
    type                = "VirtualMachineScaleSets"
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
    auto_scaling_enabled = "false"
  }

  identity {
    type                      = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  network_profile {
    load_balancer_sku = "standard"
    network_plugin    = "kubenet"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }
}
