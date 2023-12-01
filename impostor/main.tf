terraform {
  cloud {
    organization = "motorailgun"

    workspaces {
      name = "impostor-testing"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.20.0"
    }

    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.17.1"
    }
  }
}

variable "vultr_api_key" {
  type        = string
  description = "Vultr API key"
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token created at https://dash.cloudflare.com/profile/api-tokens"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Zone ID for yukari.uk"
  type        = string
}

provider "vultr" {
  api_key    = var.vultr_api_key
  rate_limit = 300
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "vultr_instance" "impostor" {
  region   = "nrt"
  plan     = "vc2-1c-1gb"
  os_id    = 535
  hostname = "impostor"
}

resource "cloudflare_record" "impostor" {
  zone_id = var.cloudflare_zone_id
  name    = "impostor"
  value   = vultr_instance.impostor.main_ip
  type    = "A"
  ttl     = 180
}
