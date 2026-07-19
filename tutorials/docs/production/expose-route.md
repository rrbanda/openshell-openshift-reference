# Expose via OpenShift Route

For production use, expose the gateway externally so CLI clients can connect without `oc port-forward`.

## Option 1: OpenShift Route (Passthrough)

Since the gateway speaks gRPC (HTTP/2), use a passthrough Route that terminates TLS at the pod level. This requires re-enabling TLS on the gateway.

### Enable TLS on the Gateway

Upgrade the Helm release with TLS enabled:

```shell
helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version 0.0.80 \
  --namespace openshell \
  --set podSecurityContext.fsGroup=null \
  --set securityContext.runAsUser=null
```

!!! note
    By removing `server.disableTls=true`, TLS is re-enabled. The `pkiInitJob` has already created the required certificates.

### Create a Passthrough Route

```shell
oc -n openshell create route passthrough openshell \
  --service=openshell \
  --port=8080
```

Get the route hostname:

```shell
oc -n openshell get route openshell -o jsonpath='{.spec.host}'
```

### Register with the CLI

Extract the client TLS bundle for the CLI:

```shell
mkdir -p ~/.config/openshell/gateways/openshift/mtls
oc -n openshell get secret openshell-client-tls \
  -o jsonpath='{.data.ca\.crt}'  | base64 -d > ~/.config/openshell/gateways/openshift/mtls/ca.crt
oc -n openshell get secret openshell-client-tls \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > ~/.config/openshell/gateways/openshift/mtls/tls.crt
oc -n openshell get secret openshell-client-tls \
  -o jsonpath='{.data.tls\.key}' | base64 -d > ~/.config/openshell/gateways/openshift/mtls/tls.key
```

Register using the route hostname:

```shell
ROUTE_HOST=$(oc -n openshell get route openshell -o jsonpath='{.spec.host}')
openshell gateway add "https://${ROUTE_HOST}:443" --name openshift-prod
openshell status
```

## Option 2: Edge-Terminated Route (TLS Disabled on Gateway)

If you prefer OpenShift's router to handle TLS termination:

```shell
oc -n openshell create route edge openshell-edge \
  --service=openshell \
  --port=8080
```

!!! warning "gRPC Limitation"
    Edge-terminated routes with gRPC require OpenShift Router 4.14+ with HTTP/2 support enabled. Verify with:

    ```shell
    oc get ingresscontroller default -n openshift-ingress-operator \
      -o jsonpath='{.status.conditions[?(@.type=="Available")].status}'
    ```

Register with the CLI (no client certs needed):

```shell
ROUTE_HOST=$(oc -n openshell get route openshell-edge -o jsonpath='{.spec.host}')
openshell gateway add "https://${ROUTE_HOST}" --name openshift-edge
```

## Option 3: Gateway API with Envoy Gateway

For more control, use the Kubernetes Gateway API:

```shell
helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version 0.0.80 \
  --namespace openshell \
  --reuse-values \
  --set grpcRoute.enabled=true \
  --set grpcRoute.gateway.create=true \
  --set grpcRoute.gateway.className=eg
```

This requires Envoy Gateway installed on the cluster. See the [Ingress documentation](https://nvidia.github.io/OpenShell/kubernetes/ingress) for details.

---

!!! tip "Next Step"
    [:octicons-arrow-right-24: Configure OIDC authentication](oidc-auth.md)
