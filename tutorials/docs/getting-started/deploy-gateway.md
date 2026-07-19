# Deploy the Gateway

This page walks through deploying the OpenShell gateway on OpenShift with the required Security Context Constraints and Helm overrides.

## Step 1: Create the Namespace

```shell
oc create ns openshell
```

## Step 2: Grant the Privileged SCC

Sandbox pods run under the `openshell-sandbox` service account and require the `privileged` SCC for network namespace setup and supervisor injection:

```shell
oc adm policy add-scc-to-user privileged -z openshell-sandbox -n openshell
```

!!! warning "Why privileged?"
    The sandbox supervisor needs to create network namespaces, configure nftables, and mount Landlock LSM — all of which require elevated privileges. The **gateway** pod itself runs unprivileged; only sandbox pods need this SCC.

## Step 3: Install the Helm Chart

=== "Latest release"

    ```shell
    helm install openshell oci://ghcr.io/nvidia/openshell/helm-chart \
      --version 0.0.80 \
      --namespace openshell \
      --set server.disableTls=true \
      --set server.auth.allowUnauthenticatedUsers=true \
      --set podSecurityContext.fsGroup=null \
      --set securityContext.runAsUser=null
    ```

    !!! warning "Evaluation only"
        `disableTls` and `allowUnauthenticatedUsers` are for quick eval. For production, configure [mTLS](../production/expose-route.md) or [OIDC](../production/oidc-auth.md).

=== "Dev build (latest main)"

    ```shell
    helm install openshell oci://ghcr.io/nvidia/openshell/helm-chart \
      --version 0.0.0-dev \
      --namespace openshell \
      --set server.disableTls=true \
      --set server.auth.allowUnauthenticatedUsers=true \
      --set podSecurityContext.fsGroup=null \
      --set securityContext.runAsUser=null
    ```

### What These Overrides Do

| Override | Reason |
|---|---|
| `server.disableTls=true` | Run gateway over plaintext HTTP. The PKI init job still creates JWT signing keys for sandbox authentication. Use only for evaluation or when TLS is terminated at the edge (e.g., OpenShift Route). |
| `podSecurityContext.fsGroup=null` | Let OpenShift's SCC admission controller assign the fsGroup instead of the chart's hardcoded value (1000). |
| `securityContext.runAsUser=null` | Let OpenShift's SCC admission controller assign the UID instead of the chart's hardcoded value (1000). |

!!! info "PKI Init Job"
    The `pkiInitJob` hook still runs automatically and creates the sandbox JWT signing Secret (`openshell-jwt-keys`). This is required for sandbox-to-gateway authentication regardless of TLS mode.

## Step 4: Wait for Deployment

```shell
oc -n openshell rollout status statefulset/openshell --timeout=120s
```

Check all pods are running:

```shell
oc -n openshell get pods
```

Expected output:

```
NAME          READY   STATUS    RESTARTS   AGE
openshell-0   1/1     Running   0          45s
```

## What Was Created

After a successful install, the following resources exist:

```shell
oc -n openshell get all,secret,configmap,sa,role,rolebinding
```

| Resource Type | Name | Purpose |
|---|---|---|
| StatefulSet | `openshell` | Gateway pod with 1Gi PVC |
| Service | `openshell` | ClusterIP on port 8080 (gRPC) |
| ConfigMap | `openshell-config` | Rendered `gateway.toml` |
| Secret | `openshell-jwt-keys` | Ed25519 JWT signing keys |
| ServiceAccount | `openshell` | Gateway identity |
| ServiceAccount | `openshell-sandbox` | Sandbox pod identity |
| Role | `openshell-sandbox` | Sandbox CR lifecycle |
| ClusterRole | `openshell-node-reader` | TokenReview + node read |

---

!!! tip "Next Step"
    [:octicons-arrow-right-24: Verify the installation](verify.md)
