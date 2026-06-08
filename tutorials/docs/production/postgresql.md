# PostgreSQL for High Availability

The default SQLite backend is per-pod and suitable for single-replica evaluation. For production with multiple gateway replicas, use PostgreSQL.

## Option 1: Bundled PostgreSQL

Deploy a PostgreSQL instance alongside the gateway using the bundled Bitnami subchart:

```shell
helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version <version> \
  --namespace openshell \
  --set podSecurityContext.fsGroup=null \
  --set securityContext.runAsUser=null \
  --set server.disableTls=true \
  --set postgres.enabled=true \
  --set postgres.primary.podSecurityContext.fsGroup=null \
  --set postgres.primary.containerSecurityContext.runAsUser=null
```

!!! note "OpenShift PostgreSQL Overrides"
    The Bitnami PostgreSQL subchart also needs its security context cleared for OpenShift SCC compatibility.

Set an explicit password (recommended for production):

```shell
  --set postgres.auth.password=my-secure-password
```

### Scale the Gateway

With PostgreSQL, you can run multiple gateway replicas:

```shell
helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version <version> \
  --namespace openshell \
  --reuse-values \
  --set replicaCount=2
```

## Option 2: External PostgreSQL

### Create the Connection Secret

```shell
oc -n openshell create secret generic pg-credentials \
  --from-literal=uri="postgresql://openshell:password@pg-host.example.com:5432/openshell?sslmode=require"
```

### Point the Gateway at It

```shell
helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version <version> \
  --namespace openshell \
  --set podSecurityContext.fsGroup=null \
  --set securityContext.runAsUser=null \
  --set server.disableTls=true \
  --set server.externalDbSecret=pg-credentials
```

## Option 3: OpenShift Database Operator (CrunchyData PGO)

If your cluster uses the CrunchyData PostgreSQL Operator:

```shell
oc apply -f - <<EOF
apiVersion: postgres-operator.crunchydata.com/v1beta1
kind: PostgresCluster
metadata:
  name: openshell-db
  namespace: openshell
spec:
  postgresVersion: 16
  instances:
    - replicas: 2
      dataVolumeClaimSpec:
        accessModes: [ReadWriteOnce]
        resources:
          requests:
            storage: 5Gi
  backups:
    pgbackrest:
      repos:
        - name: repo1
          volume:
            volumeClaimSpec:
              accessModes: [ReadWriteOnce]
              resources:
                requests:
                  storage: 5Gi
EOF
```

Wait for the cluster to be ready, then extract the connection URI:

```shell
PG_URI=$(oc -n openshell get secret openshell-db-pguser-openshell-db \
  -o jsonpath='{.data.uri}' | base64 -d)

oc -n openshell create secret generic pg-credentials \
  --from-literal=uri="${PG_URI}"

helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
  --version <version> \
  --namespace openshell \
  --reuse-values \
  --set server.externalDbSecret=pg-credentials
```

## Verify Database Connectivity

Check that the gateway starts without database errors:

```shell
oc -n openshell logs statefulset/openshell --tail=20
```

The gateway logs `Server listening` when the database connection is healthy. If PostgreSQL is unreachable, you'll see connection errors in the log output.

---

!!! success "Production Ready"
    With external access, OIDC, and PostgreSQL configured, your OpenShell deployment is production-ready.

    [:octicons-arrow-right-24: Troubleshooting](../troubleshooting.md) if you encounter issues.
