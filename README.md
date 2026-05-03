# lab-devops-proxmox

Laboratório DevOps self-hosted: cluster Kubernetes (K3s) em VMs Proxmox, provisionado por **Ansible** + **Terraform**, pronto pra GitOps com **ArgoCD**. Pensado pra estudar a stack moderna ponta-a-ponta em hardware caseiro.

---

## Arquitetura

Três camadas, cada uma com sua ferramenta:

| Camada | Alvo | Ferramenta | Diretório |
|---|---|---|---|
| 1. Infra (host físico) | Proxmox: rede, NAT, VMs | Ansible + Terraform | `infra/ansible-proxmox/`, `infra/terraform/` |
| 2. Plataforma | K3s nas VMs | Ansible | `infra/ansible-k3s/` |
| 3. Apps | Workloads no K8s | GitOps (ArgoCD) | `gitops/` *(em construção)* |

**Topologia atual:**

```
  Cliente (Mac)                                    LAN 192.168.15.0/24
       │
       │ ssh -J root@proxmox  +  LocalForward 6443
       ▼
  ┌──────────────────────────────────────────┐
  │ Proxmox VE  (Wi-Fi → bridge vmbr0, NAT)  │  .200
  └──────────────┬───────────────────────────┘
                 │  vmbr0 (rotas /32 por VM)
   ┌─────────────┼─────────────┬──────────────┐
   ▼             ▼             ▼              ▼
 master-01   worker-01     worker-02     db-postgres-01
  .100         .101          .103            .102
  └──────── cluster K3s ──────┘
```

A API server do K3s é acessada do Mac via túnel SSH (`ssh -fN k3s-master`); o `~/.ssh/config` é configurado automaticamente pelo playbook do master.

---

## Estrutura

```
infra/
├── ansible-proxmox/       # rede, NAT, rotas /32, /etc/network/interfaces, template, provision-vm
├── ansible-k3s/           # instala K3s no master + workers, exporta kubeconfig + túnel SSH
└── terraform/             # provisiona VMs declarativamente (alternativa ao provision-vm.yml)
gitops/                    # ArgoCD bootstrap + apps  (em construção)
k8s/                       # manifests Kustomize da API de exemplo
main.go, Dockerfile        # API Go simples ("Hello GitOps") pra exercitar o pipeline CI/CD
```

---

## Pré-requisitos

- **Servidor Proxmox VE 8.x** (homelab, mini-PC, etc.)
- **Cliente** (macOS/Linux):
  - Ansible 2.15+
  - Terraform 1.5+
  - `kubectl`
  - Chave SSH cuja pública esteja autorizada no Proxmox e nas VMs

---

## Setup inicial

```bash
git clone git@github.com:jeferson-guedes/lab-devops-proxmox.git
cd lab-devops-proxmox

# 1) Variáveis (copiar .example → real, editar)
cp infra/ansible-proxmox/inventory.example.yml          infra/ansible-proxmox/inventory.yml
cp infra/ansible-proxmox/group_vars/proxmox/vars.example.yml  infra/ansible-proxmox/group_vars/proxmox/vars.yml
cp infra/ansible-k3s/inventory/hosts.example.yml        infra/ansible-k3s/inventory/hosts.yml
cp infra/ansible-k3s/group_vars/all.example.yml         infra/ansible-k3s/group_vars/all.yml

# 2) Preparar o Proxmox (rede, rotas, template Ubuntu 24.04)
ansible-playbook \
  -i infra/ansible-k3s/inventory/hosts.yml \
  -i infra/ansible-proxmox/inventory.yml \
  infra/ansible-proxmox/network.yml \
  infra/ansible-proxmox/playbook.yml \
  infra/ansible-proxmox/template.yml

# 3) Provisionar uma VM (repetir para master + workers)
ansible-playbook -i infra/ansible-k3s/inventory/hosts.yml -i infra/ansible-proxmox/inventory.yml \
  infra/ansible-proxmox/provision-vm.yml \
  -e vmid=100 -e name=k8s-master-01 -e ip=192.168.15.100

# 4) Instalar K3s no cluster
ansible-playbook -i infra/ansible-k3s/inventory/hosts.yml infra/ansible-k3s/site.yml

# 5) Túnel SSH + kubectl
ssh -fN k3s-master
KUBECONFIG=~/.kube/config-homelab kubectl get nodes
```

---

## Adicionar um novo worker

```bash
# 1) Provisiona VM
ansible-playbook -i infra/ansible-k3s/inventory/hosts.yml -i infra/ansible-proxmox/inventory.yml \
  infra/ansible-proxmox/provision-vm.yml \
  -e vmid=104 -e name=k8s-worker-03 -e ip=192.168.15.104

# 2) Adicionar k8s-worker-03 em infra/ansible-k3s/inventory/hosts.yml (grupo k3s_worker)

# 3) Atualizar rotas /32 no Proxmox
ansible-playbook -i infra/ansible-k3s/inventory/hosts.yml -i infra/ansible-proxmox/inventory.yml \
  infra/ansible-proxmox/playbook.yml

# 4) Join no cluster
ansible-playbook -i infra/ansible-k3s/inventory/hosts.yml infra/ansible-k3s/site.yml \
  --limit 'k3s_master,k8s-worker-03'
```

---

## Decisões de arquitetura

- **K3s em vez de kubeadm**: menor footprint, single binary, suficiente pra homelab.
- **SSH tunnel pro API server**: VMs em NAT atrás do Proxmox (Wi-Fi não permite bridge L2). O túnel é portátil — funciona de qualquer rede com SSH no Proxmox. Detalhes em `infra/ansible-k3s/roles/k3s_master/tasks/main.yml`.
- **iptables-persistent + sysctl.d + systemd unit**: cada peça da configuração de rede do Proxmox sobrevive a reboot pelo seu mecanismo padrão (regras em `/etc/iptables/rules.v4`, `ip_forward` em `/etc/sysctl.d/`, rotas /32 via `k3s-cluster-routes.service`). Nada em `post-up` do `interfaces`.
- **Ansible para Proxmox + opcional Terraform**: Ansible é imperativo idempotente; Terraform é declarativo com state. Pra VMs do Proxmox, ambos funcionam — o repo tem os dois pra estudo.

---

## Roadmap

- [x] Camada 1 — Ansible para Proxmox (rede, rotas, template, provision)
- [x] Camada 2 — Ansible para K3s (master + workers, túnel SSH)
- [ ] Camada 3 — GitOps com ArgoCD (`gitops/bootstrap/`)
  - [ ] `ingress-nginx`, `MetalLB`, `cert-manager`
  - [ ] App de exemplo (Go API) gerenciado por ArgoCD
- [ ] CI — GitHub Actions → Docker Hub
- [ ] Cloud — `infra/cloud/` em Terraform (EKS/GKE) usando o **mesmo** `gitops/`

---

## Stack

Proxmox VE · K3s · Ansible · Terraform · Kustomize · *(em breve)* ArgoCD · Helm · GitHub Actions
