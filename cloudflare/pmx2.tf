resource "random_id" "tunnel_secret_pmx2" {
  byte_length = 35
}

resource "cloudflare_tunnel" "pmx2" {
  account_id = var.cloudflare_account_id
  name       = "pmx2"
  secret     = random_id.tunnel_secret_pmx2.b64_std
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
  value   = cloudflare_tunnel.cname
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

resource "cloudflare_access_policy" "github_pmx2" {
  application_id = cloudflare_access_application.coder.id
  zone_id        = var.cloudflare_zone_id
  name           = "policy for pmx2/allow github auth"
  precedence     = "1"
  decision       = "allow"

  include {
    login_method = [ var.cloudflare_idp_github_id ]
  }
}
