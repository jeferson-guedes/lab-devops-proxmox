# Acessar o ArgoCD

## 1. Túnel SSH pro API server

```bash
ssh -fN k3s-master
```

O alias `k3s-master` é configurado pelo `infra/ansible-k3s/site.yml` no seu `~/.ssh/config` (com `LocalForward` da 6443).

## 2. Port-forward da UI

```bash
KUBECONFIG=~/.kube/config-homelab make -C gitops/bootstrap port-forward
```

Mantenha a janela aberta (foreground).

## 3. Abrir a UI

- **URL:** https://localhost:8080
- Aceitar o aviso de certificado auto-assinado.
- **Usuário:** `admin`
- **Senha inicial:** ver `gitops/bootstrap/credentials.local.md` *(gitignored)*

## Recuperar a senha admin

```bash
KUBECONFIG=~/.kube/config-homelab make -C gitops/bootstrap password
```

Funciona enquanto você não rotacionou — depois disso, o secret `argocd-initial-admin-secret` é apagado pelo próprio ArgoCD. Se rotacionar, atualize `credentials.local.md` ou apague.

## Reset de tudo (cuidado)

```bash
KUBECONFIG=~/.kube/config-homelab make -C gitops/bootstrap uninstall
```

Remove o namespace `argocd` inteiro — incluindo a Application raiz.
