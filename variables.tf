variable "rg" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Resources location in Azure"
}

variable "cluster_name" {
  type        = string
  description = "AKS cluster name in Azure"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
}

variable "system_node_count" {
  type        = number
  description = "Number of AKS worker nodes"
}

variable "node_resource_group" {
  type        = string
  description = "Resource group name for cluster resources in Azure"
}

variable "azurerm_subscription_id" {
  description = "The Azure subscription ID."
  type        = string
}

variable "azurerm_tenant_id" {
  description = "The Azure tenant ID."
  type        = string
}

variable "azurerm_client_id" {
  description = "The Azure client ID."
  type        = string
}
variable "azurerm_client_secret" {
  description = "The Azure client secret."
  type        = string
}
