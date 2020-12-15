Terraform - Hosting a static (SPA) website using Azure Blob Storage and Frontdoor
--
Lean and Mean static (SPA) website hosting for cheap in Azure.  

This Terraform plan creates the following: 
- Azure Resource Group 
- Azure Storage Account 
- Azure FrontDoor
- Custom Domain + SSL managed by FrontDoor
- Http -> https redirect

# Usage
*Applying this plan can take more than 20 minutes when you use a Frontdoor managed SSL certificate*
1) If not already available, setup a resource group and storage account that will contain the Terraform remote state:
```chmod +x ./setup_tfstate.sh && ./setup_tfstate.sh```
2) Change `default.tf` and update the backend with your generated storage account details.
2) Override default variables by using a ```local.auto.tfvars``` file and make sure that you have a storage account setup for remote state storage. 
```local.auto.tfvars
web_hostname = "your_hostname"
dns_suffix = "your.domain.com"
dns_rg = "yourdnsresourcegroup"
resource_group_name = "yourwebsite-prod-rg"
```
3) Sign-in met Azure-cli ```az login``` and select proper subscription ```az account set --subscription "SUBSCRIPTION NAME"```
4) Run your Terraform commands:
```
terraform init
terraform plan
terraform apply
```
5) When deployed you can upload your static files to the storage account blob storage (in $web). Do this with a CI/CD pipeline or whatever suits you most.  

# Resources
[HashiCorp Azure Provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)  


## Authors

**Jvdp** - *Initial work* - [Jvdp](https://github.com/jvdp11)
