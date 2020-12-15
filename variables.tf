variable "web_hostname" {
  description = "Sets the web hostname"
  default     = "staticwebsite"
}

variable "dns_suffix" {
  description = "Sets the DNS suffix needed for CNAME creation"
  default     = "subdomain.yourdomain.com"
}

variable "dns_rg" {
  description = "Resource Group where DNS zone is located"
  default     = "dns-prod-rg"
}

variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = true
}

variable "resource_group_name" {
  description = "The name of the resource group in which resources are created"
  default     = "staticwebsite-prod-rg"
}

variable "location" {
  description = "The location of the resource group in which resources are created"
  default     = "westeurope"
}

variable "storage_account_name" {
  description = "The name of the storage account to be created"
  default     = "stgwebwesteurope01"
}

variable "account_kind" {
  description = "The kind of storage account."
  default     = "StorageV2"
}

variable "sku" {
  description = "The SKU of the storage account."
  default     = "Standard_GRS"
}

variable "enable_https_traffic" {
  description = "Configure the storage account to accept requests from secure connections only. Possible values are `true` or `false`"
  default     = true
}

variable "enable_static_website" {
  description = "Controls if static website to be enabled on the storage account. Possible values are `true` or `false`"
  default     = true
}

variable "assign_identity" {
  description = "Specifies the identity type of the Storage Account. At this time the only allowed value is SystemAssigned."
  default     = true
}

variable "index_path" {
  description = "path from your repo root to index.html"
  default     = "index.html"
}

variable "custom_404_path" {
  description = "path from your repo root to your custom 404 page"
  default     = "404.html"
}

variable "allowed_methods" {
  type        = list(string)
  description = " A list of http headers that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`."
  default = [
    "GET",
    "HEAD"
  ]
}

variable "allowed_origins" {
  type        = list(string)
  description = "A list of origin domains that will be allowed by CORS."
  default     = ["*"]
}

variable "allowed_headers" {
  type        = list(string)
  description = "A list of headers that are allowed to be a part of the cross-origin request."
  default     = ["*"]
}

variable "exposed_headers" {
  type        = list(string)
  description = "A list of response headers that are exposed to CORS clients."
  default     = ["*"]
}

variable "max_age_in_seconds" {
  type        = number
  description = "The number of seconds the client should cache a preflight response.  Defaults to 2 days"
  default     = 60 * 60 * 24 * 2
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}