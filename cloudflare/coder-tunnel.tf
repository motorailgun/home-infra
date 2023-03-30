terraform {
  cloud {
    organization = "motorailgun"

    workspaces {
      name = "home-infra"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.2.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "cloudflare_token" {
  description = "Cloudflare API token created at https://dash.cloudflare.com/profile/api-tokens"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Account ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Zone ID for yukari.uk"
  type        = string
  sensitive   = true
}

variable "cloudflare_idp_github_id" {
  description = "ID of IdP of GitHub Auth"
  type        = string
  sensitive   = true
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

provider "random" {
}

resource "random_id" "tunnel_secret" {
  byte_length = 35
}

resource "cloudflare_tunnel" "coder" {
  account_id = var.cloudflare_account_id
  name       = "coder"
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_record" "coder" {
  zone_id = var.cloudflare_zone_id
  name    = "coder"
  value   = cloudflare_tunnel.coder.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_access_application" "coder" {
  zone_id                   = var.cloudflare_zone_id
  name                      = "coder"
  domain                    = "coder.yukari.uk"
  type                      = "self_hosted"
  session_duration          = "24h"
  allowed_idps              = [var.cloudflare_idp_github_id]
  auto_redirect_to_identity = true
}

resource "cloudflare_access_policy" "github" {
  application_id = cloudflare_access_application.coder.id
  zone_id        = var.cloudflare_zone_id
  name           = "policy for coder/allow github auth"
  precedence     = "1"
  decision       = "allow"

  include {
    login_method = [ var.cloudflare_idp_github_id ]
  }
}
