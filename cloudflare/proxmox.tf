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
      version = "~> 5.1"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

variable "cloudflare_account_id" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

variable "cloudflare_idp_github_id" {
  type = string
}

variable "cloudflare_token" {
  type = string
}

data "cloudflare_zone" "target" {
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "pmx" {
  account_id = var.cloudflare_account_id
  name       = "proxmox"
  config_src = "cloudflare"
}

resource "cloudflare_dns_record" "canel" {
  name    = "canel"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.pmx.id}.cfargotunnel.com"
  proxied = true
  settings = {
    flatten_cname = false
  }
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "yuzuru" {
  name    = "yuzuru"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.pmx.id}.cfargotunnel.com"
  proxied = true
  settings = {
    flatten_cname = false
  }
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "minase" {
  name    = "minase"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.pmx.id}.cfargotunnel.com"
  proxied = true
  settings = {
    flatten_cname = false
  }
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "averuni" {
  name    = "averuni"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.pmx.id}.cfargotunnel.com"
  proxied = true
  settings = {
    flatten_cname = false
  }
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_zero_trust_access_policy" "github_pmx" {
  account_id = var.cloudflare_account_id
  decision   = "allow"
  include = [
    {
      login_method = {
        id = var.cloudflare_idp_github_id
      }
    },
  ]
  name             = "github-auth"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "pmx" {
  account_id = var.cloudflare_account_id
  config = {
    ingress = [
      {
        hostname = "minase.${data.cloudflare_zone.target.name}"
        origin_request = {
          no_tls_verify = true
          access = {
            aud_tag     = [cloudflare_zero_trust_access_application.pmx.id]
            deny_access = true
          }
        }
        service = "https://192.168.1.150:8006"
      },
      {
        hostname = "averuni.${data.cloudflare_zone.target.name}"
        origin_request = {
          no_tls_verify = true
          access = {
            aud_tag     = [cloudflare_zero_trust_access_application.pmx.id]
            deny_access = true
          }
        }
        service = "https://192.168.1.200:8006"
      },
      {
        hostname = "canel.${data.cloudflare_zone.target.name}"
        origin_request = {
          no_tls_verify = true
          access = {
            aud_tag     = [cloudflare_zero_trust_access_application.pmx.id]
            deny_access = true
          }
        }
        service = "https://192.168.1.175:8006"
      },
      {
        hostname = "yuzuru.${data.cloudflare_zone.target.name}"
        origin_request = {
          no_tls_verify = true
          access = {
            aud_tag     = [cloudflare_zero_trust_access_application.pmx.id]
            deny_access = true
          }
        }
        service = "https://192.168.1.225:8006"
      },
      {
        service = "http_status:404"
      },
    ]
    warp_routing = {
      enabled = true
    }
  }
  source    = "cloudflare"
  tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.pmx.id
}

resource "cloudflare_zero_trust_access_application" "pmx" {
  account_id                = var.cloudflare_account_id
  allowed_idps              = [var.cloudflare_idp_github_id]
  app_launcher_visible      = true
  auto_redirect_to_identity = true
  destinations = [
    {
      type = "public"
      uri  = "minase.${data.cloudflare_zone.target.name}"
    },
    {
      type = "public"
      uri  = "averuni.${data.cloudflare_zone.target.name}"
    },
    {
      type = "public"
      uri  = "canel.${data.cloudflare_zone.target.name}"
    },
    {
      type = "public"
      uri  = "yuzuru.${data.cloudflare_zone.target.name}"
    },
  ]
  domain                     = "minase.${data.cloudflare_zone.target.name}"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "proxmox"
  options_preflight_bypass   = false
  policies = [
    {
      decision = "allow"
      exclude = [
      ]
      include = [
        {
          login_method = {
            id = var.cloudflare_idp_github_id
          }
        },
      ]
      name       = "github-auth"
      precedence = 1
      require = [
      ]
    },
  ]
  self_hosted_domains          = ["minase.${data.cloudflare_zone.target.name}", "averuni.${data.cloudflare_zone.target.name}", "canel.${data.cloudflare_zone.target.name}", "yuzuru.${data.cloudflare_zone.target.name}"]
  service_auth_401_redirect    = true
  session_duration             = "24h"
  skip_app_launcher_login_page = false
  type                         = "self_hosted"
  tags                         = []
}
