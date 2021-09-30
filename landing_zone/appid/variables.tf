##############################################################################
# App ID Variables
##############################################################################

variable appid_name {
    type        = string
    description = "Name of the app id instance"
}

variable region {
    type        = string
    description = "Region where App ID will be provisioned"
}

variable entity_id {
    type        = string
    description = "Entity ID for the SAML provider"
}

variable sign_in_url {
    type        = string
    description = "Sign in URL for the SAML provider"
}

variable cert {
    type        = string
    description = "Certificate for the SAML provider"
}

##############################################################################
