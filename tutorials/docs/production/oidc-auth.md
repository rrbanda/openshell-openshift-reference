# OIDC Authentication

For multi-user environments, configure OpenID Connect authentication so each user gets their own identity.

## Using OpenShift's Built-in OAuth Server

OpenShift includes an OAuth server that can be used as the OIDC provider.

### Step 1: Create an OAuth Client

```shell
oc create -f - <<EOF
apiVersion: oauth.openshift.io/v1
kind: OAuthClient
metadata:
  name: openshell-cli
grantMethod: auto
redirectURIs:
  - http://127.0.0.1:9876/callback
EOF
```

### Step 2: Get the OAuth Issuer URL

```shell
oc get authentication.config.openshift.io cluster \
  -o jsonpath='{.spec.serviceAccountIssuer}'
```

Typically this is `https://oauth-openshift.apps.<cluster-domain>` or the API server URL.

### Step 3: Configure the Gateway

```shell
ISSUER=$(oc get authentication.config.openshift.io cluster \
  -o jsonpath='{.spec.serviceAccountIssuer}')

helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version <version> \
  --namespace openshell \
  --reuse-values \
  --set server.oidc.issuer="${ISSUER}" \
  --set server.oidc.audience=openshell-cli
```

### Step 4: Register with OIDC

```shell
openshell gateway add https://<gateway-endpoint> \
  --name openshift-oidc \
  --oidc-issuer "${ISSUER}" \
  --oidc-client-id openshell-cli
```

The CLI will open a browser for the OAuth flow on first use.

## Using an External Identity Provider

### Keycloak

```shell
helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version <version> \
  --namespace openshell \
  --reuse-values \
  --set server.oidc.issuer=https://keycloak.example.com/realms/openshell \
  --set server.oidc.audience=openshell-cli \
  --set server.oidc.rolesClaim=realm_access.roles \
  --set server.oidc.adminRole=openshell-admin \
  --set server.oidc.userRole=openshell-user
```

### Microsoft Entra ID

```shell
helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version <version> \
  --namespace openshell \
  --reuse-values \
  --set server.oidc.issuer=https://login.microsoftonline.com/<tenant-id>/v2.0 \
  --set server.oidc.audience=<application-id> \
  --set server.oidc.rolesClaim=roles \
  --set server.oidc.adminRole=openshell-admin \
  --set server.oidc.userRole=openshell-user
```

## Custom CA for OIDC Issuer

If your OIDC provider uses a private CA (common with in-cluster Keycloak or OpenShift's OAuth):

```shell
oc -n openshell create configmap oidc-ca \
  --from-file=ca.crt=/path/to/issuer-ca.crt

helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version <version> \
  --namespace openshell \
  --reuse-values \
  --set server.oidc.caConfigMapName=oidc-ca
```

---

!!! tip "Next Step"
    [:octicons-arrow-right-24: Configure PostgreSQL for HA](postgresql.md)
