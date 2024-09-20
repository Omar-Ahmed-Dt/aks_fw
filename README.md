# Azure Kubernetes Service (AKS) with Azure Firewall - Terraform Setup

This Terraform configuration deploys an Azure Kubernetes Service (AKS) cluster with enhanced network security by routing all traffic through Azure Firewall. Below is an overview of the resources that are created and their configuration details.

## Resources Created

### 1. **Resource Group**
- A resource group (`azurerm_resource_group.rg`) is created to logically hold all related resources such as the virtual network, subnets, firewall, and the AKS cluster.

### 2. **Virtual Network (VNet)**
- A virtual network (`azurerm_virtual_network.vnet`) with the IP address range of `10.0.0.0/16` is created to host the AKS cluster and the Azure Firewall.

### 3. **Subnets**
- **AKS Subnet**: A dedicated subnet (`azurerm_subnet.aks_subnet`) with the IP range `10.0.1.0/24` is created for the AKS nodes.
- **Firewall Subnet**: A dedicated subnet (`azurerm_subnet.firewall_subnet`) with the IP range `10.0.2.0/24` is created for deploying Azure Firewall.

### 4. **Public IP for Firewall**
- A public IP address (`azurerm_public_ip.firewall_public_ip`) is created for Azure Firewall, allowing it to route traffic to and from the internet.

### 5. **Azure Firewall**
- Azure Firewall (`azurerm_firewall.firewall`) is deployed within the virtual network, configured to secure traffic flow using the dedicated public IP and firewall subnet.

### 6. **Firewall Policy**
- A firewall policy (`azurerm_firewall_policy.firewall_policy`) is defined to control traffic. It applies security rules enforced by Azure Firewall.

### 7. **Firewall Rules**
- **Network Rule Collection**: A network rule is created to block all traffic by default (`azurerm_firewall_policy_rule_collection_group`).
- **Application Rule Collection**: A rule that allows only HTTPS traffic from the domain `*.poseidondev.website`, ensuring secure and controlled traffic.

### 8. **Route Table**
- A route table (`azurerm_route_table.aks_route_table`) is created for the AKS subnet. All traffic from this subnet is routed through Azure Firewall by setting up a route (`azurerm_route.route_through_firewall`).

### 9. **Subnet Route Table Association**
- The route table is associated (`azurerm_subnet_route_table_association`) with the AKS subnet, ensuring that all traffic from the AKS cluster passes through Azure Firewall.

### 10. **Azure Kubernetes Service (AKS) Cluster**
An AKS cluster (`azurerm_kubernetes_cluster.aks`) is deployed with the following configurations:
- **Node Pool**: The cluster is configured with a single node pool using VM size `Standard_D2pls_v5` without auto-scaling.
- **System-Assigned Identity**: The cluster uses a system-assigned identity for managing Azure resources.
- **Network Profile**: The network is configured using the `kubenet` plugin, with a custom service CIDR `10.1.0.0/16` and DNS service IP `10.1.0.10`.

## How to Use This Setup

1. Clone the repository containing this Terraform code.
2. Update the `main.tf` file with your desired values, such as subscription details, region, etc.
3. Initialize the Terraform project:
   ```bash
   terraform init
   ```
4. Review the plan to ensure resources will be created as expected:
   ```bash
   terraform plan
   ```
5. Apply the changes to create the infrastructure:
   ```bash
   terraform apply
   ```