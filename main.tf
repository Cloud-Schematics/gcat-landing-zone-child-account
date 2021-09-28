##############################################################################
# Parent Account IBM Cloud Provider
##############################################################################

provider ibm {
    alias                 = "parent_account"
    ibmcloud_api_key      = var.ibmcloud_api_key
    region                = var.region
    ibmcloud_timeout      = 60
}

##############################################################################


##############################################################################
# Get Secrets Manager Data
##############################################################################

data ibm_resource_group resource_group {
  provider = ibm.parent_account
  name     = var.secrets_manager_resource_group
}


data ibm_resource_instance secrets_manager {
  provider          = ibm.parent_account
  name              = var.secrets_manager_name
  service           = "secrets-manager"
  resource_group_id = data.ibm_resource_group.resource_group.id
}

data ibm_secrets_manager_secret secrets_manager_secret {
  provider    = ibm.parent_account
  instance_id = data.ibm_resource_instance.secrets_manager.guid
  secret_type = "arbitrary"
  secret_id   = var.secret_guid
}

##############################################################################


##############################################################################
# Child Account Provider
##############################################################################

provider ibm {
  ibmcloud_api_key = data.ibm_secrets_manager_secret.secrets_manager_secret.payload
  region           = var.region
  ibmcloud_timeout = 60
}

##############################################################################


##############################################################################
# Create Landing Zone
##############################################################################

module landing_zone {
  source               = "./landing_zone"
  prefix               = var.prefix
  region               = var.region
  resource_group       = var.resource_group
  access_groups        = var.access_groups
  classic_access       = var.classic_access
  subnets              = var.subnets
  use_public_gateways  = var.use_public_gateways
  acl_rules            = var.acl_rules
  security_group_rules = var.security_group_rules
}

##############################################################################