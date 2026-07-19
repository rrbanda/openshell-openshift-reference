# Verify Installation

Confirm the gateway is healthy and reachable before creating sandboxes.

## Check Gateway Health

The gateway exposes `/healthz` (liveness) and `/readyz` (readiness) on port 8081:

```shell
oc -n openshell port-forward svc/openshell 8081:8081 &
curl -s http://127.0.0.1:8081/healthz
curl -s http://127.0.0.1:8081/readyz
kill %1
```

Both should return HTTP 200.

## Connect the CLI

Open a port-forward to the gRPC service:

```shell
oc -n openshell port-forward svc/openshell 8080:8080 &
```

!!! tip "Keep the port-forward running"
    The `&` backgrounds the port-forward. It must stay alive for CLI commands to work. If it dies, restart it. For production without port-forward, see [Expose via Route](../production/expose-route.md).

In the same or another terminal, register the gateway:

```shell
openshell gateway add http://127.0.0.1:8080 --local --name openshift
```

Check connectivity:

```shell
openshell status
```

Expected output (format may vary by version):

```
Server Status

  Gateway: openshift
  Server:  http://127.0.0.1:8080
  Status:  Connected
  Version: <gateway version>
```

## Inspect Gateway Logs

```shell
oc -n openshell logs statefulset/openshell --tail=50
```

Look for:

```
WARN openshell_server::cli: TLS disabled — listening on plaintext HTTP
INFO openshell_server::cli: Starting OpenShell server bind=0.0.0.0:8080
INFO openshell_server: Server listening address=0.0.0.0:8080
INFO openshell_server: Health server listening address=0.0.0.0:8081
```

!!! failure "Common Issues"
    If the pod is in `CrashLoopBackOff`, check:

    - SCC assignment: `oc get pod openshell-0 -n openshell -o yaml | grep -A5 securityContext`
    - JWT secret exists: `oc -n openshell get secret openshell-jwt-keys`
    - Events: `oc -n openshell get events --sort-by='.lastTimestamp'`

    See [Troubleshooting](../troubleshooting.md) for detailed resolution steps.

## Verify RBAC

Confirm the gateway service account has the required permissions:

```shell
oc auth can-i create sandboxes.agents.x-k8s.io \
  --as=system:serviceaccount:openshell:openshell \
  -n openshell
```

Should return `yes`.

```shell
oc auth can-i create tokenreviews.authentication.k8s.io \
  --as=system:serviceaccount:openshell:openshell
```

Should return `yes`.

---

!!! success "Installation Complete"
    Your OpenShell gateway is running on OpenShift. Continue to create your first sandbox.

    [:octicons-arrow-right-24: Create your first sandbox](../sandboxes/first-sandbox.md)
