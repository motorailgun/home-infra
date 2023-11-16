terraform {
  cloud {
    organization = "motorailgun"

    workspaces {
      name = "home-infra-cloudflare"
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

resource "cloudflare_tunnel" "pmx2" {
  account_id = var.cloudflare_account_id
  name       = "pmx2"
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_tunnel_config" "pmx2" {
  account_id = var.cloudflare_account_id
  tunnel_id = cloudflare_tunnel.coder.id
  config {
    ingress_rule {
      service = "http://192.168.1.200:8006"
    }
  }
}

resource "cloudflare_record" "pmx2" {
  zone_id = var.cloudflare_zone_id
  name    = "pmx2"
  value   = cloudflare_tunnel..cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_access_application" "pmx2" {
  zone_id                   = var.cloudflare_zone_id
  name                      = "pmx2"
  domain                    = "pmx2.yukari.uk"
  type                      = "self_hosted"
  session_duration          = "24h"
  allowed_idps              = [var.cloudflare_idp_github_id]
  auto_redirect_to_identity = true
}

resource "cloudflare_access_policy" "github" {
  application_id = cloudflare_access_application.coder.id
  zone_id        = var.cloudflare_zone_id
  name           = "policy for pmx2/allow github auth"
  precedence     = "1"
  decision       = "allow"

  include {
    login_method = [ var.cloudflare_idp_github_id ]
  }
}
