output "firewall_public_ip" {
  value = azurerm_public_ip.firewall_public_ip.ip_address
}