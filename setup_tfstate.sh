#!/bin/bash
#
# script to setup remote state storage (and more if neccesary, such as initial keyvaults containing passwords,etc. )
# author: Jvdp
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NO_COLOR='\033[0m'

osType="$(uname -s)"
case "${osType}" in
    Linux*)     
        echo -e "Selecting ${osType}"
        xsed='sed'
        ;;
    Darwin*)
        echo -e "Selecting ${osType}"
        for app in jq gnu-sed
        do 
            if brew ls --versions ${app} > /dev/null; then
                echo -e "${GREEN}${app} available${NO_COLOR}"
            else
                echo -e "${RED}${app} is not installed, installing... ${NO_COLOR}"
                brew install ${app}
            fi
        done
        xsed='gsed'
        ;;
    *)          
        echo -e "Machine type not detected"
        exit 1
esac
RANDOMIZER=`base64 </dev/urandom | tr -dc '0-9' | head -c3`
CUST_NAME=tpl
RESOURCE_GROUP_NAME=$CUST_NAME-terraform-p-rg
STORAGE_ACCOUNT_NAME=terraformstg
CONTAINER_NAME=terraform-tfstate

if [ $(az group exists --name $RESOURCE_GROUP_NAME) = false ]; then
    RG_STATUS="${GREEN}Not Exist${NO_COLOR}"
else
    RG_STATUS="${RED}Already exist, you should abort${NO_COLOR}"
fi
SUBSCRIPTION=`az account show |jq -r '.name'`
echo -e "############################################################################"
echo -e "${RED}Only use this script for initial setup${NO_COLOR}"
echo -e ""
echo -e "Azure Subscription: ${BLUE}${SUBSCRIPTION}${NO_COLOR}"
echo -e "${RESOURCE_GROUP_NAME}: ${RG_STATUS}"

echo -e "############################################################################"

read -p "Are you sure to proceed? [Y/n]:" -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${RED} User aborted."
else
    echo ""
    # Create resource group
    echo -e "${BLUE}Creating resource group: $RESOURCE_GROUP_NAME ... ${NO_COLOR}"
    az group create --name $RESOURCE_GROUP_NAME --location westeurope --tags "Environment=Production" "Project=StaticWebSite" --output none
    # Create storage account
    echo -e "${BLUE}Creating storage account: $STORAGE_ACCOUNT_NAME$RANDOMIZER ... ${NO_COLOR}"
    az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME$RANDOMIZER --sku Standard_LRS --encryption-services blob --kind StorageV2 --output none
    # Get storage account key
    ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME$RANDOMIZER --query [0].value -o tsv)
    # Create blob container
    echo -e "${BLUE}Creating storage container: $CONTAINER_NAME ... ${NO_COLOR}"
    az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME$RANDOMIZER --account-key $ACCOUNT_KEY --output none
    
    echo -e ""
    echo -e "############################################################################"
    echo -e "${BLUE}storage_account_name:${NO_COLOR} $STORAGE_ACCOUNT_NAME$RANDOMIZER"
    echo -e "${BLUE}container_name:${NO_COLOR} $CONTAINER_NAME"
    echo -e "${BLUE}account_key:${NO_COLOR} $ACCOUNT_KEY"

fi
