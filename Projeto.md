# Projeto: Lab DevOps + Platform (GitOps)

Este documento define a arquitetura e o plano de execução para a criação do seu laboratório open-source de DevOps simulando um fluxo de produção 100% realístico utilizando a metodologia GitOps.

## Visão Geral do Fluxo Desejado
1. **Desenvolvimento:** O código de uma API simples é alterado e sofre "push" para o GitHub.
2. **CI (Continuous Integration):** O GitHub Actions intercepta o push, constrói a imagem Docker e envia para o Docker Hub.
3. **Manifestos:** Os arquivos YAML do Kubernetes são gerenciados usando `Kustomize` no próprio repositório.
4. **CD (Continuous Deployment):** O `ArgoCD` (rodando dentro do cluster) detecta as mudanças no repositório do GitHub e aplica as alterações (sincronização) automaticamente no Kubernetes sem a necessidade de comandos manuais.

> [!IMPORTANT]
> Este é o estado da arte do DevOps moderno. Ao terminar isso, você terá o mesmo fluxo de deploy utilizado por grandes empresas de tecnologia (como Netflix, iFood e Nubank).

## User Review Required / Open Questions

Antes de iniciarmos a mão na massa, preciso que você responda a algumas perguntas de design para o projeto:

1. **Linguagem da API:** Qual linguagem você prefere usar para criar a "API simples"? (Ex: Node.js, Python/FastAPI, Go, Java).
2. **Onde vamos rodar agora?** Você quer que a gente construa toda essa esteira e instale o ArgoCD no seu **OrbStack (Mac)** hoje como uma Prova de Conceito (PoC), para que depois você apenas aponte o ArgoCD do seu Mini-PC para o GitHub quando o hardware estiver pronto?
3. **Automação (CI):** Você prefere que eu já escreva o arquivo do **GitHub Actions** (`.github/workflows/ci.yml`) para automatizar a publicação no Docker Hub, ou você quer fazer isso via terminal manualmente primeiro para entender o processo?

## Fases de Implementação

### Fase 1: Fundação da Aplicação (CI)
Nesta fase, criaremos a base do software e a automação de build.
- [NEW] Código fonte da API simples (Retornando um "Hello World" com a versão).
- [NEW] `Dockerfile` otimizado para produção (multi-stage build).
- [NEW] Pipeline de integração contínua (GitHub Actions) para publicar no Docker Hub.

### Fase 2: Estrutura do Kubernetes (Kustomize)
Nesta fase, organizaremos os manifestos no padrão de mercado.
- [NEW] Pasta `k8s/base/` contendo `deployment.yaml`, `service.yaml`.
- [NEW] Pasta `k8s/base/kustomization.yaml`.
- [NEW] Pasta de overlay (ex: `k8s/overlays/production/`) demonstrando como o Kustomize sobrepõe configurações da imagem e réplicas.

### Fase 3: A Mágica do GitOps (ArgoCD)
Nesta fase, conectaremos o cluster ao seu repositório Open Source no GitHub.
- Instalação oficial do ArgoCD no seu cluster Kubernetes local.
- Acesso à interface web do ArgoCD e obtenção da senha administrativa.
- Criação de um `Application` no ArgoCD que observará a pasta `k8s/overlays/production` do seu repositório.

## Verification Plan

### Teste de Fogo (O fluxo completo)
A comprovação de que o projeto foi um sucesso se dará pelo seguinte teste:
1. Faremos um commit mudando o retorno da nossa API (ex: de "v1" para "v2").
2. Observaremos o GitHub Actions rodar, compilar a imagem e gerar a nova tag no Docker Hub.
3. Atualizaremos o `kustomization.yaml` no GitHub com a nova tag da imagem.
4. Observaremos a interface do ArgoCD detectando a mudança (*Out of Sync*) e aplicando automaticamente (*Syncing*) os novos Pods no cluster, **sem que você precise digitar `kubectl apply` em nenhum momento.**
