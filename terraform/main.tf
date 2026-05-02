terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.68.1"
    }
  }
}

# =========================================================
# Variaveis do Provider (valores em secrets.auto.tfvars)
# =========================================================

variable "proxmox_endpoint" {
  description = "URL da API do Proxmox. Ex: https://192.168.15.200:8006/"
  type        = string
}

variable "proxmox_username" {
  description = "Usuario de API. Em producao, use terraform@pve com token."
  type        = string
}

variable "proxmox_password" {
  description = "Senha ou token do usuario de API."
  type        = string
  sensitive   = true
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  # insecure=true é necessário pois o Proxmox local usa certificado auto-assinado.
  # Em produção real, substitua por um certificado assinado (ex: Let's Encrypt + Nginx proxy).
  insecure = true
}

# =========================================================
# Variáveis de Rede
# =========================================================

variable "network_gateway" {
  description = "IP do gateway da rede interna (o proprio Proxmox faz NAT)."
  type        = string
}

variable "network_dns" {
  description = "Servidor DNS publico para as VMs."
  type        = string
  default     = "8.8.8.8"
}

# =========================================================
# Variáveis de Acesso
# =========================================================

variable "ssh_key" {
  description = "Chave SSH publica do administrador para acesso as VMs."
  type        = string
  sensitive   = true
}

# =========================================================
# Variáveis das VMs
# =========================================================

variable "vm_master" {
  description = "Configuracoes do K8s Master."
  type = object({
    name      = string
    node_name = string
    vm_id     = number
    ip        = string
  })
}

variable "vm_worker" {
  description = "Configuracoes do K8s Worker."
  type = object({
    name      = string
    node_name = string
    vm_id     = number
    ip        = string
  })
}

variable "vm_db_postgres" {
  description = "Configuracoes da VM do banco de dados Postgres."
  type = object({
    name      = string
    node_name = string
    vm_id     = number
    ip        = string
  })
}

# =========================================================
# 1. K8s Master
# =========================================================
resource "proxmox_virtual_environment_vm" "k8s_master" {
  name      = var.vm_master.name
  node_name = var.vm_master.node_name
  vm_id     = var.vm_master.vm_id

  clone {
    vm_id = 9000
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES" # Melhor compatibilidade com workloads modernos
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
    discard      = "on" # Melhora performance em SSDs NVMe
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.vm_master.ip}/24"
        gateway = var.network_gateway
      }
    }
    dns {
      servers = [var.network_dns]
    }
    user_account {
      keys = [var.ssh_key]
    }
  }
}

# =========================================================
# 2. K8s Worker
# =========================================================
resource "proxmox_virtual_environment_vm" "k8s_worker" {
  name      = var.vm_worker.name
  node_name = var.vm_worker.node_name
  vm_id     = var.vm_worker.vm_id

  clone {
    vm_id = 9000
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 3072
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
    discard      = "on"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.vm_worker.ip}/24"
        gateway = var.network_gateway
      }
    }
    dns {
      servers = [var.network_dns]
    }
    user_account {
      keys = [var.ssh_key]
    }
  }
}

# =========================================================
# 3. PostgreSQL Database
# =========================================================
resource "proxmox_virtual_environment_vm" "db_postgres" {
  name      = var.vm_db_postgres.name
  node_name = var.vm_db_postgres.node_name
  vm_id     = var.vm_db_postgres.vm_id

  clone {
    vm_id = 9000
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
    discard      = "on"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.vm_db_postgres.ip}/24"
        gateway = var.network_gateway
      }
    }
    dns {
      servers = [var.network_dns]
    }
    user_account {
      keys = [var.ssh_key]
    }
  }
}
