# Bootstrap do ArgoCD no cluster K3s.
# 1-shot: depois disso, tudo é gerenciado por GitOps a partir de gitops/apps/.
#
# Uso:
#   export KUBECONFIG=~/.kube/config-homelab
#   ssh -fN k3s-master              # garante o túnel 6443 aberto
#   make install                    # instala ArgoCD + Application raiz
#   make password                   # mostra a senha admin inicial
#   make port-forward               # expõe a UI em https://localhost:8080

NAMESPACE      ?= argocd
ARGOCD_VERSION ?= stable
ARGOCD_MANIFEST = https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/install.yaml

.PHONY: install uninstall password port-forward status

install:
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	# --server-side: a CRD applicationsets do ArgoCD estoura o limite de 262144B
	# da annotation last-applied-configuration usada pelo kubectl apply client-side.
	kubectl apply -n $(NAMESPACE) --server-side=true --force-conflicts -f $(ARGOCD_MANIFEST)
	@echo
	@echo "Aguardando argocd-server ficar pronto (até 5min)..."
	kubectl -n $(NAMESPACE) wait --for=condition=available deployment/argocd-server --timeout=300s
	kubectl apply -f root-app.yaml
	@echo
	@echo "ArgoCD instalado. Próximos passos:"
	@echo "  make password       # senha admin inicial"
	@echo "  make port-forward   # UI em https://localhost:8080"

uninstall:
	-kubectl delete -f root-app.yaml --ignore-not-found
	-kubectl -n $(NAMESPACE) delete -f $(ARGOCD_MANIFEST) --ignore-not-found
	-kubectl delete namespace $(NAMESPACE) --ignore-not-found

password:
	@kubectl -n $(NAMESPACE) get secret argocd-initial-admin-secret \
	  -o jsonpath='{.data.password}' | base64 -d; echo

port-forward:
	@echo "UI: https://localhost:8080  (login: admin / make password)"
	kubectl -n $(NAMESPACE) port-forward svc/argocd-server 8080:443

status:
	kubectl -n $(NAMESPACE) get pods,svc
	@echo
	kubectl get applications -n $(NAMESPACE)
