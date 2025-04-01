resource "cloudflare_zero_trust_tunnel_cloudflared" "grafana" {
  account_id    = var.cloudflare_account_id
  name          = "grafana"
  config_src = "cloudflare"
}

resource "cloudflare_dns_record" "grafana" {
  name     = "grafana"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.grafana.id}.cfargotunnel.com"
  proxied  = true
  settings = {
    flatten_cname = false
  }
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "grafana" {
  account_id = var.cloudflare_account_id
  config = {
    ingress = [
      {
        hostname = "grafana.${data.cloudflare_zone.target.name}"
        origin_request = {
          no_tls_verify            = true
          access = {
            aud_tag = [cloudflare_zero_trust_access_application.grafana.id]
            deny_access = true
          }
        }
        # should be applied later, after provider's bug gets fixed
        service = "https://172.16.1.2:3000"
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
  tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.grafana.id
}

resource "cloudflare_zero_trust_access_application" "grafana" {
  account_id                   = var.cloudflare_account_id
  allowed_idps                 = [var.cloudflare_idp_github_id]
  app_launcher_visible         = true
  auto_redirect_to_identity    = true
  destinations = [
    {
      type        = "public"
      uri         = "grafana.${data.cloudflare_zone.target.name}"
    },
  ]
  domain                     = "grafana.${data.cloudflare_zone.target.name}"
  enable_binding_cookie      = false
  http_only_cookie_attribute = true
  name                       = "grafana"
  options_preflight_bypass   = false
  policies = [
    {
      decision         = "allow"
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
  self_hosted_domains          = ["grafana.${data.cloudflare_zone.target.name}"]
  service_auth_401_redirect    = true
  session_duration             = "24h"
  skip_app_launcher_login_page = false
  type                         = "self_hosted"
  tags = []
}
