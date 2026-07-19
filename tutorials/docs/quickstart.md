---
hide:
  - toc
---

# Quickstart: Zero to Running Agent in 10 Steps

One page. Copy-paste every command. End with a working AI agent inside a sandboxed environment on OpenShift.

!!! note "Prerequisites"
    You need: `oc` logged into an OpenShift 4.14+ cluster (cluster-admin), Helm 3.x installed, and internet access to pull images from GHCR.

---

## 1. Install the OpenShell CLI

```shell
curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh
```

## 2. Install the Agent Sandbox controller

```shell
oc apply -f https://github.com/kubernetes-sigs/agent-sandbox/releases/latest/download/manifest.yaml
```

## 3. Create namespace and bind the privileged SCC

```shell
oc create ns openshell
oc adm policy add-scc-to-user privileged -z openshell-sandbox -n openshell
```

## 4. Install the OpenShell gateway

```shell
helm install openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version 0.0.80 \
  --namespace openshell \
  --set podSecurityContext.fsGroup=null \
  --set securityContext.runAsUser=null \
  --set server.auth.allowUnauthenticatedUsers=true \
  --set server.disableTls=true
```

!!! info "Version"
    Tested with chart `0.0.80`. TLS disabled for quick eval. See [Production](production/expose-route.md) for TLS setup.

## 5. Wait for the gateway to be ready

```shell
oc -n openshell rollout status statefulset/openshell --timeout=120s
```

## 6. Connect your CLI to the gateway

Open a **separate terminal** for the port-forward (it must stay running):

```shell
oc -n openshell port-forward svc/openshell 8080:8080 &
```

Register the gateway:

```shell
openshell gateway add http://127.0.0.1:8080 --local --name openshift
openshell status
```

You should see `Status: Connected`.

## 7. Create a sandbox

```shell
openshell sandbox create --name quickstart
```

You're now inside the sandbox. Try:

```shell
whoami
# sandbox
```

## 8. See default-deny in action

From inside the sandbox:

```shell
curl -s https://api.github.com/zen
```

```text
curl: (56) Received HTTP code 403 from proxy after CONNECT
```

Everything is blocked by default. The agent can reach nothing unless you allow it.

## 9. Allow an endpoint

Open a **new terminal** (keep the sandbox session open) and run:

```shell
openshell policy update quickstart \
  --add-endpoint api.github.com:443:read-only:rest:enforce \
  --binary /usr/bin/curl \
  --wait
```

## 10. Verify it works

Back in the sandbox terminal:

```shell
curl -s https://api.github.com/zen
```

```text
Anything added dilutes everything else.
```

It works. The policy allowed read-only access to GitHub's API for curl only.

---

!!! success "Done"
    You have a working OpenShell deployment on OpenShift with policy-enforced sandboxing.

    **What you proved:**

    - Default-deny networking (step 8)
    - Per-binary, per-host, L7 policy (step 9)
    - Hot-reload without restart (step 10)

## What's next?

| Goal | Page |
|---|---|
| Configure inference routing (run Claude/ADK inside sandbox) | [Inference Routing](sandboxes/inference-routing.md) |
| Learn network policies in depth | [Network Policies](sandboxes/network-policies.md) |
| Expose gateway externally (no port-forward) | [OpenShift Route](production/expose-route.md) |
| Understand agent architecture concepts | [Agent Architecture](concepts/agent-architecture.md) |
| Interactive stack wizard | [Stack Wizard](concepts/stack-wizard.html) |

## Cleanup

```shell
openshell sandbox delete quickstart
helm uninstall openshell -n openshell
oc delete ns openshell
```
