#!/usr/bin/env bash
cat - << EOF
modify_headers:
  - '/~d $PROXMOX_URL/CF-Access-Client-Id/$CF_ACCESS_CLIENT_ID'
  - '/~d $PROXMOX_URL/CF-Access-Client-Secret/$CF_ACCESS_CLIENT_SECRET'
EOF
