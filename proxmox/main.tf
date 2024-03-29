terraform {
  cloud {
    organization = "motorailgun"

    workspaces {
      name = "home-infra-proxmox"
    }
  }

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.14"
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
  pm_tls_insecure     = true
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret

  pm_proxy_server = "http://localhost:8080"
}



resource "proxmox_vm_qemu" "kubernetes-master" {
  name        = "kubernetes-master"
  desc        = "Master node of kubernetes cluster"
  target_node = "takahashi"

  clone      = "debian-template"
  full_clone = true

  cpu     = "host"
  cores   = 3
  sockets = 1
  memory  = 4096

  scsihw = "virtio-scsi-pci"

  agent   = 1
  qemu_os = "linux"

  onboot       = true
  force_create = false

  os_type   = "cloud-init"
  ipconfig0 = "ip=192.168.1.152/24,gw=192.168.1.1"

  ciuser     = "debian"
  cipassword = "debian"
  ssh_user   = "debian"

  sshkeys         = var.pm_ssh_public_key
  ssh_private_key = var.pm_ssh_private_key

  disk {
    type    = "virtio"
    storage = "local-lvm"
    size    = "45G"
    ssd     = 1
  }

  network {
    bridge    = "vmbr0"
    firewall  = false
    link_down = false
    macaddr   = "52:61:7A:4B:24:95"
    model     = "virtio"
    mtu       = 0
    queues    = 0
    rate      = 0
    tag       = -1
  }
}


resource "proxmox_vm_qemu" "haproxy" {
  name        = "haproxy"
  desc        = "haproxy"
  target_node = "takahashi"

  clone      = "debian-template"
  full_clone = true

  cpu     = "host"
  cores   = 1
  sockets = 1
  memory  = 1024

  scsihw = "virtio-scsi-pci"

  onboot       = true
  force_create = false

  os_type   = "cloud-init"
  ipconfig0 = "ip=192.168.1.153/24,gw=192.168.1.1"

  ciuser     = "debian"
  cipassword = "debian"
  ssh_user   = "debian"

  sshkeys         = var.pm_ssh_public_key
  ssh_private_key = var.pm_ssh_private_key
}


resource "proxmox_vm_qemu" "builder" {
  name        = "builder"
  desc        = "builder"
  target_node = "averuni"

  clone      = "debian-template-2"
  full_clone = true

  cpu     = "host"
  cores   = 4
  sockets = 1
  memory  = 8192

  qemu_os = "linux"

  scsihw = "virtio-scsi-pci"

  onboot       = true
  force_create = false

  os_type   = "cloud-init"
  ipconfig0 = "ip=192.168.1.210/24,gw=192.168.1.1"

  ciuser     = "debian"
  cipassword = "debian"
  ssh_user   = "debian"

  sshkeys         = var.pm_ssh_public_key
  ssh_private_key = var.pm_ssh_private_key

  disk {
    type    = "virtio"
    storage = "local-lvm"
    size    = "64G"
    ssd     = 1
  }

}
