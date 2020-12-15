output "storage_account_id" {
  value       = azurerm_storage_account.storageaccount.id
  description = "The ID of the storage account."
}

output "storage_account_name" {
  value       = azurerm_storage_account.storageaccount.name
  description = "Storage account name."
}

output "static_website_url" {
  value       = azurerm_storage_account.storageaccount.primary_web_host
  description = "static web site URL."
}

output "dns_cname_record" {
  value       = azurerm_dns_cname_record.website.fqdn
  description = "FQDN of the CNAME record created."
}