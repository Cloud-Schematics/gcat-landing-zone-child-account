##############################################################################
# Create and Configure App ID
##############################################################################

resource ibm_resource_instance app_id {
    name     = var.appid_name
    service  = "appid"
    plan     = "graduated-tier"
    location = var.region
}

resource ibm_appid_idp_facebook disable_facebook {
  tenant_id = ibm_resource_instance.app_id.guid
  is_active = false
}

resource ibm_appid_idp_custom disable_idp {
  tenant_id  = ibm_resource_instance.app_id.guid
  is_active  = false
  public_key = null
}
         
resource ibm_appid_idp_saml saml {
  tenant_id = ibm_resource_instance.app_id.guid
  is_active = true
  config {
    entity_id        = var.entity_id
    sign_in_url      = var.sign_in_url
    display_name     = "%s"
    encrypt_response = true
    sign_request     = false
    certificates     = [ var.cert ]
  }
}

##############################################################################
