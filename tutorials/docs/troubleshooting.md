# Troubleshooting

Common issues when running OpenShell on OpenShift and their resolutions.

## Gateway Pod Issues

### Pod stuck in `CreateContainerConfigError`

**Symptom**: Gateway pod cannot start, events show volume mount errors.

```shell
oc -n openshell describe pod openshell-0
```

**Cause**: JWT signing Secret does not exist (PKI init job failed or was skipped).

**Fix**: Check if the certgen hook job ran:

```shell
oc -n openshell get jobs -l app.kubernetes.io/name=openshell
```

If no job exists, the hook may have been skipped. Manually trigger:

```shell
helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version 0.0.80 --namespace openshell --reuse-values
```

---

### Pod in `CrashLoopBackOff`

**Symptom**: Gateway starts but immediately exits.

**Diagnosis**:

```shell
oc -n openshell logs openshell-0 --previous
```

Common causes:

| Log message | Cause | Fix |
|---|---|---|
| `permission denied: /var/openshell` | PVC ownership mismatch | Ensure `podSecurityContext.fsGroup=null` is set |
| `failed to bind 0.0.0.0:8080` | Port conflict | Check for other services on port 8080 |
| `database error` | SQLite locked or corrupt | Delete PVC: `oc -n openshell delete pvc openshell-data-openshell-0` and recreate |
| `jwt signing key not found` | Secret missing | Check `oc -n openshell get secret openshell-jwt-keys` |

---

### Pod rejected by SCC

**Symptom**: Pod cannot be scheduled, events mention security context.

```shell
oc -n openshell get events | grep -i "forbidden\|scc"
```

**Fix**: Verify the overrides are applied:

```shell
helm get values openshell -n openshell
```

Should show:

```yaml
podSecurityContext:
  fsGroup: null
securityContext:
  runAsUser: null
```

---

## Sandbox Pod Issues

### Sandbox stuck in `Pending`

**Symptom**: Sandbox pod never starts.

**Diagnosis**:

```shell
oc -n openshell get pods -l openshell.ai/managed-by=openshell
oc -n openshell describe pod <sandbox-pod-name>
```

Common causes:

| Event | Cause | Fix |
|---|---|---|
| `FailedScheduling: insufficient memory` | Node resources exhausted | Add nodes or set resource limits |
| `couldn't find SCC` / `unable to validate` | SCC not bound | `oc adm policy add-scc-to-user privileged -z openshell-sandbox -n openshell` |
| `ImagePullBackOff` | Cannot pull sandbox image | Check GHCR access or configure `sandboxImagePullSecrets` |

---

### Sandbox in `ERROR` phase

**Symptom**: `openshell sandbox get` shows `ERROR`.

**Diagnosis**: Check the sandbox pod logs:

```shell
POD=$(oc -n openshell get pods -l openshell.ai/sandbox-name=<name> -o name)
oc -n openshell logs $POD
```

Common causes:

- **Supervisor cannot reach gateway**: Check `OPENSHELL_ENDPOINT` env var in the pod
- **SA token exchange failed**: Check `oc -n openshell logs statefulset/openshell | grep TokenReview`
- **Policy load failed**: Check for OPA errors in sandbox logs

---

## Network Issues

### Sandbox cannot reach external services

**Symptom**: `curl` from inside sandbox times out.

**Cause**: Network policy or OPA denial.

**Check policy denials**:

```shell
openshell logs <sandbox-name> | grep "action=deny"
```

**Check Kubernetes NetworkPolicy**:

```shell
oc -n openshell get networkpolicy
```

The default NetworkPolicy only restricts **ingress** to sandbox pods (SSH from gateway only). It does not restrict egress. If custom NetworkPolicies exist, ensure sandbox pods can reach the internet.

---

### Gateway cannot reach sandbox pods (SSH)

**Symptom**: `openshell sandbox connect` hangs.

**Diagnosis**:

```shell
oc -n openshell get networkpolicy
```

Verify the gateway pod labels match the NetworkPolicy ingress selector.

---

## Helm Issues

### `helm install` fails with OCI auth error

**Symptom**: Cannot pull chart from `ghcr.io`.

**Fix**: GHCR public packages should not require auth. If your cluster has a restrictive egress policy:

```shell
helm pull oci://ghcr.io/nvidia/openshell/helm-chart --version 0.0.80
helm install openshell ./helm-chart-0.0.80.tgz -n openshell ...
```

---

### Upgrade fails with immutable field error

**Symptom**: `helm upgrade` returns "field is immutable" errors.

**Fix for StatefulSet changes** (e.g., adding volumes):

```shell
oc -n openshell delete statefulset openshell --cascade=orphan
helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version 0.0.80 --namespace openshell --reuse-values
```

This recreates the StatefulSet without deleting the running pod.

---

## Diagnostic Commands

Quick reference for gathering diagnostic information:

```shell
# Full cluster state dump
oc -n openshell get all,secret,configmap,sa,role,rolebinding,pvc

# Gateway configuration
oc -n openshell get configmap openshell-config -o jsonpath='{.data.gateway\.toml}'

# Recent events (sorted)
oc -n openshell get events --sort-by='.lastTimestamp' | tail -20

# SCC assignments
oc get scc privileged -o jsonpath='{.users}' | tr ',' '\n' | grep openshell

# Agent Sandbox CRs
oc -n openshell get sandboxes.agents.x-k8s.io

# Gateway health endpoints
oc -n openshell exec statefulset/openshell -- curl -s localhost:8081/healthz
oc -n openshell exec statefulset/openshell -- curl -s localhost:8081/readyz
```

---

!!! info "Still Stuck?"
    If none of the above resolves your issue:

    1. Gather the diagnostic output above
    2. Check the [OpenShell GitHub Discussions](https://github.com/NVIDIA/OpenShell/discussions)
    3. File a bug with the diagnostic output in the [Agent Diagnostic section](https://github.com/NVIDIA/OpenShell/issues/new?template=bug_report.yml)
