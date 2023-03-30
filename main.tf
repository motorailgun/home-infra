terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.13"
    }
  }

  cloud {
    organization = "motorailgun"

    workspaces {
      name = "home-infra"
    }
  }
}

variable "pm_api_token_id" {
  type        = string
  description = "Proxmox API token ID"
}

variable "pm_api_token_secret" {
  type        = string
  sensitive   = true
  description = "Proxmox API token secret"
}

variable "pm_api_url" {
  type        = string
  sensitive   = true
  description = "Proxmox URL"
}

variable "pm_ssh_public_key" {
  type        = string
  sensitive   = true
  description = "SSH public key"
}

variable "pm_ssh_private_key" {
  type        = string
  sensitive   = true
  description = "SSH private key"
}

provider "proxmox" {
  pm_tls_insecure     = false
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
}



resource "proxmox_vm_qemu" "cf-tunnel" {
  name        = "cloudflare-tunnel"
  desc        = "VM for Cloudflare Tunnel"
  target_node = "takahashi"

  clone      = "debian-template"
  full_clone = true

  cpu     = "host"
  cores   = 1
  sockets = 1
  memory  = 1024

  onboot       = true
  force_create = true

  os_type   = "cloud-init"
  ipconfig0 = "ip=192.168.1.151/24,gw=192.168.1.1"

  ciuser     = "debian"
  cipassword = "debian"
  ssh_user   = "debian"

  sshkeys = var.pm_ssh_public_key

  ssh_private_key = var.pm_ssh_private_key
}
