######################################
# Local Variables                    #
######################################
locals {
  web_hostname              = var.web_hostname
  dns_suffix                = var.dns_suffix
  dns_rg                    = var.dns_rg
  account_tier              = (var.account_kind == "FileStorage" ? "Premium" : split("_", var.sku)[0])
  account_replication_type  = (local.account_tier == "Premium" ? "LRS" : split("_", var.sku)[1])
  resource_group_name       = element(coalescelist(azurerm_resource_group.rg.*.name, [var.resource_group_name]), 0)
  location                  = element(coalescelist(azurerm_resource_group.rg.*.location, [var.location]), 0)
  if_static_website_enabled = var.enable_static_website ? [{}] : []
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = merge({ "Name" = format("%s", var.resource_group_name) }, var.tags, )
}

######################################
# Create the storage account         #
######################################
resource "azurerm_storage_account" "storageaccount" {
  name                      = var.storage_account_name
  resource_group_name       = local.resource_group_name
  location                  = local.location
  account_kind              = var.account_kind
  account_tier              = local.account_tier
  account_replication_type  = local.account_replication_type
  enable_https_traffic_only = var.enable_https_traffic
  tags                      = merge({ "Name" = format("%s", var.storage_account_name) }, var.tags, )

  dynamic "static_website" {
    for_each = local.if_static_website_enabled
    content {
      index_document     = var.index_path
      error_404_document = var.custom_404_path
    }
  }

  blob_properties {
    cors_rule {
      allowed_methods    = var.allowed_methods
      allowed_origins    = var.allowed_origins
      allowed_headers    = var.allowed_headers
      exposed_headers    = var.exposed_headers
      max_age_in_seconds = var.max_age_in_seconds
    }
  }

  identity {
    type = var.assign_identity ? "SystemAssigned" : null
  }
}

#######################################################
# Create DNS CNAME + Front Door resource              #
#######################################################
resource "azurerm_dns_cname_record" "website" {
  name                = local.web_hostname
  zone_name           = local.dns_suffix
  resource_group_name = local.dns_rg
  ttl                 = 60
  record              = "${local.web_hostname}-FrontDoor.azurefd.net"
}

resource "azurerm_frontdoor" "staticweb" {
  name                                         = "${local.web_hostname}-FrontDoor"
  resource_group_name                          = element(coalescelist(azurerm_resource_group.rg.*.name, [var.resource_group_name]), 0)
  enforce_backend_pools_certificate_name_check = false
  routing_rule {
    name               = "01-${var.web_hostname}HttpRedirectRule"
    accepted_protocols = ["Http"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["${var.web_hostname}FrontendEndpoint1", "${var.web_hostname}FrontendEndpoint2"]
    redirect_configuration {
      redirect_protocol = "HttpsOnly"
      redirect_type     = "Moved"
    }
  }

  routing_rule {
    name               = "02-${var.web_hostname}toStaticWeb-https"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["${var.web_hostname}FrontendEndpoint1", "${var.web_hostname}FrontendEndpoint2"]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "${local.web_hostname}blobpool"
    }
  }

  backend_pool_load_balancing {
    name = "${var.web_hostname}LoadBalancingSettings"
  }

  backend_pool_health_probe {
    name     = "${var.web_hostname}HealthProbeSetting"
    path     = "/index.html"
    protocol = "Https"
  }

  backend_pool {
    name = "${var.web_hostname}blobpool"
    backend {
      host_header = azurerm_storage_account.storageaccount.primary_web_host
      address     = azurerm_storage_account.storageaccount.primary_web_host
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = "${var.web_hostname}LoadBalancingSettings"
    health_probe_name   = "${var.web_hostname}HealthProbeSetting"
  }

  frontend_endpoint {
    name      = "${var.web_hostname}FrontendEndpoint1"
    host_name = "${local.web_hostname}-FrontDoor.azurefd.net"
  }
  frontend_endpoint {
    name      = "${var.web_hostname}FrontendEndpoint2"
    host_name = "${var.web_hostname}.${var.dns_suffix}"
  }

}

resource "azurerm_frontdoor_custom_https_configuration" "staticweb_custom_https" {
  frontend_endpoint_id              = azurerm_frontdoor.staticweb.frontend_endpoint[1].id
  custom_https_provisioning_enabled = true
  resource_group_name               = element(coalescelist(azurerm_resource_group.rg.*.name, [var.resource_group_name]), 0) # deprecated but needed: https://github.com/terraform-providers/terraform-provider-azurerm/pull/9357
  custom_https_configuration {
    # use FrontDoor to manage the SSL certificate, if you want to bring your own certificate, please look here:
    # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/frontdoor_custom_https_configuration#custom_https_configuration
    certificate_source = "FrontDoor"
  }
}

