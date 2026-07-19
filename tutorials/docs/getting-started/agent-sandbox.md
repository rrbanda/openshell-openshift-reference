# Install Agent Sandbox

OpenShell uses the Kubernetes Agent Sandbox controller to provision sandbox pods. The controller and CRDs must be installed before the OpenShell Helm chart.

## Install the Controller

=== "Option 1: Red Hat build of Agent Sandbox (OpenShift)"

    Follow the installation instructions at [Deploying Red Hat build of Agent Sandbox](https://docs.redhat.com/en/documentation/red_hat_build_of_agent_sandbox). The Red Hat build includes version-pinned OpenShift compatibility and creates CRDs (`Sandbox`, `SandboxClaim`, `SandboxTemplate`, `SandboxWarmPool`) in `v1beta1`.

=== "Option 2: Upstream k8s-sigs operator"

    Apply the latest upstream release manifest:

    ```shell
    oc apply -f https://github.com/kubernetes-sigs/agent-sandbox/releases/latest/download/manifest.yaml
    ```

Both options create:

- The `agent-sandbox-system` namespace
- Agent Sandbox CRDs (`sandboxes.agents.x-k8s.io`)
- The Agent Sandbox controller deployment

## Verify the Controller

Wait for the controller pod to reach `Running`:

```shell
oc -n agent-sandbox-system get pods -w
```

Expected output:

```
NAME                                        READY   STATUS    RESTARTS   AGE
agent-sandbox-controller-6b8f9d4c5f-x2k7p  1/1     Running   0          30s
```

Press ++ctrl+c++ to stop watching once it's running.

## Verify the CRD

```shell
oc get crd sandboxes.agents.x-k8s.io
```

!!! note "Air-Gapped Clusters"
    For disconnected environments, mirror the manifest and the controller image (`registry.k8s.io/agent-sandbox/agent-sandbox-controller`) to your internal registry, then update the image reference in the manifest before applying.

---

!!! tip "Next Step"
    [:octicons-arrow-right-24: Deploy the OpenShell gateway](deploy-gateway.md)
