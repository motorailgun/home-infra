terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.13"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure = true
}



resource "proxmox_vm_qemu" "cf-tunnel" {
  name        = "cloudflare-tunnel"
  desc        = "VM for Cloudflare Tunnel"
  target_node = "takahashi"

  clone = "debian-template"
  full_clone = true

  cpu = "host"
  cores   = 1
  sockets = 1
  memory  = 1024

  onboot = true
  force_create = true

  os_type   = "cloud-init"
  ipconfig0 = "ip=192.168.1.151/24,gw=192.168.1.1"

  ciuser = "debian"
  cipassword = "debian"
  ssh_user = "debian"

  sshkeys = <<EOF
EOF

}

