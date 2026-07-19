# OpenShell on OpenShift — Reference Architecture

Production-grade deployment of [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) on Red Hat OpenShift, featuring full GitOps with ArgoCD, Vault-backed secrets via External Secrets Operator, and an end-to-end tutorial.

## What's Here

| Path | Purpose |
|---|---|
| `app-of-apps.yaml` | Single ArgoCD entry point — deploys the entire stack |
| `argocd-app.yaml` | OpenShell Application (Helm chart + kustomize) |
| `base/` | Shared Helm values, namespace, SCC binding |
| `overlays/openshift-dev/` | Dev overlay: TLS disabled, ESO SecretStore + ExternalSecret |
| `infra/vault/` | Vault server ArgoCD Application (Helm chart) |
| `infra/vault-config/` | Vault configuration Job (auth, policies, JWT keygen) |
| `tutorials/` | MkDocs Material tutorial site (published to GH Pages) |
| `tutorials/docs/agent-stack-decision-guide/` | Interactive agent stack decision guide (workflow vs agent, OpenClaw/Hermes, LangGraph/ADK) |
| `scripts/hooks/` | Pre-commit secrets scanner |
| `.github/workflows/` | GH Pages publish workflow |

## Quick Start

### Manual Path (Tutorial)

Follow the [tutorial](tutorials/docs/index.md) for a step-by-step walkthrough:

```shell
# Install Agent Sandbox CRDs
oc apply -f https://github.com/kubernetes-sigs/agent-sandbox/releases/latest/download/manifest.yaml

# Create namespace + SCC
oc create ns openshell
oc adm policy add-scc-to-user privileged -z openshell-sandbox -n openshell

# Deploy
helm install openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version 0.0.80 \
  --namespace openshell \
  --set server.disableTls=true \
  --set podSecurityContext.fsGroup=null \
  --set securityContext.runAsUser=null

# Verify
oc -n openshell rollout status statefulset/openshell
```

### GitOps Path (ArgoCD + Vault + ESO)

```shell
# Install Agent Sandbox CRDs
oc apply -f https://github.com/kubernetes-sigs/agent-sandbox/releases/latest/download/manifest.yaml

# Deploy everything via App-of-Apps
oc apply -f app-of-apps.yaml
```

ArgoCD then automatically deploys Vault (wave 0), configures auth + generates JWT keys (wave 1), and deploys OpenShell with ESO-managed secrets (wave 2).

## Architecture

```
User (openshell CLI)
  |
  | gRPC (plaintext or mTLS)
  v
OpenShell Gateway (StatefulSet, openshell namespace)
  |
  | Sandbox CR
  v
Agent Sandbox Controller (agent-sandbox-system)
  |
  | creates Pod
  v
Sandbox Pod (policy-enforced, supervisor injected)
  |
  | ConnectSupervisor stream back to gateway
  v
Gateway relays SSH/exec/TCP to CLI
```

### Secret Flow (GitOps Path)

```
Vault Config Job (generates Ed25519 keys)
  --> stores in Vault at openshell/jwt-keys
      --> ESO SecretStore authenticates to Vault
          --> ESO ExternalSecret syncs to K8s Secret
              --> Gateway pod mounts Secret as volume
```

No secrets in Git. No manual secret handling after initial ArgoCD apply.

## Prerequisites

| Component | Required | Notes |
|---|---|---|
| OpenShift 4.14+ | Yes | Tested on 4.20 |
| Helm 3.x | Yes | For manual path |
| Agent Sandbox CRDs | Yes | One-time cluster install |
| OpenShift GitOps (ArgoCD) | GitOps path only | Operator from OperatorHub |
| External Secrets Operator | GitOps path only | Operator from OperatorHub |

## Security

- Pre-commit hook blocks credentials from entering Git
- All secrets generated at deploy time or sourced from Vault
- Sandbox pods use privileged SCC (required for network namespace isolation)
- Gateway pod runs unprivileged with all capabilities dropped
- NetworkPolicy restricts sandbox SSH ingress to gateway only

## Tutorial Site

The `tutorials/` directory builds a MkDocs Material documentation site:

```shell
cd tutorials
pip install -r requirements.txt
mkdocs serve
```

Published to GitHub Pages automatically on push to `main`.

## Tested On

| Component | Version |
|---|---|
| OpenShift | 4.20.22 (Kubernetes 1.33) |
| Helm chart | 0.0.80 |
| Agent Sandbox | v0.4.6 |
| External Secrets Operator | v1 API |
| Vault | 1.19 (dev mode) |

## License

Apache-2.0
