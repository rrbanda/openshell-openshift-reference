# Connect an Agent

OpenShell sandboxes are designed to host autonomous AI agents. This page shows how to run an agent inside a sandbox.

!!! warning "Required: Configure inference first"
    Agents need to call LLMs. Before running any agent, you must:

    1. **Configure inference routing** on the gateway (see [Inference Routing](inference-routing.md))
    2. **Allow `inference.local`** in the sandbox policy:

    ```shell
    openshell policy update <sandbox-name> --add-endpoint inference.local:443 --wait
    ```

    Without this, the agent will fail with `connection denied` when trying to call a model.

## Run an Agent

=== "Claude Code"

    ```shell
    openshell sandbox create --name agent-sandbox
    ```

    Inside the sandbox:

    ```shell
    ANTHROPIC_BASE_URL=https://inference.local \
    ANTHROPIC_API_KEY=unused \
    claude --bare
    ```

=== "Google ADK"

    ```shell
    openshell sandbox create --name agent-sandbox
    ```

    Inside the sandbox:

    ```shell
    BASE_URL=https://inference.local/v1 \
    API_KEY=unused \
    python agent.py
    ```

=== "OpenAI Codex"

    ```shell
    openshell sandbox create --name agent-sandbox
    ```

    Inside the sandbox:

    ```shell
    OPENAI_BASE_URL=https://inference.local/v1 \
    OPENAI_API_KEY=unused \
    codex
    ```

=== "Custom Agent"

    ```shell
    openshell sandbox create --name agent-sandbox \
      --image registry.example.com/my-agent:latest \
      -- python /app/agent.py
    ```

    Set `BASE_URL=https://inference.local/v1` in your agent's environment to use OpenShell inference routing.

The agent runs with:

- **Process isolation** — dropped privileges, seccomp
- **Filesystem isolation** — Landlock LSM restricts file access
- **Network isolation** — all egress routes through a policy-enforced proxy
- **Credential masking** — agent calls `inference.local`, never sees real API keys

This creates a sandbox and immediately launches `claude` as the entrypoint process. The agent runs with:

- **Process isolation** — dropped privileges, seccomp
- **Filesystem isolation** — Landlock LSM restricts file access
- **Network isolation** — all egress routes through a policy-enforced proxy

## Run a Custom Agent Image

If your agent has specific dependencies, use a custom image:

```shell
openshell sandbox create \
  --name custom-agent \
  --image registry.example.com/team/my-agent:latest \
  --wait -- /entrypoint.sh
```

!!! note "Image Pull Secrets"
    For private registries, create a pull secret in the `openshell` namespace:

    ```shell
    oc -n openshell create secret docker-registry regcred \
      --docker-server=registry.example.com \
      --docker-username="$USER" \
      --docker-password="$TOKEN"
    ```

    Then configure the gateway:

    ```shell
    helm upgrade openshell oci://ghcr.io/nvidia/openshell/helm-chart \
      --version 0.0.80 \
      --namespace openshell \
      --reuse-values \
      --set server.sandboxImagePullSecrets[0].name=regcred
    ```

## Monitor Agent Activity

### View Logs

```shell
openshell logs agent-sandbox
```

### Follow Logs in Real-Time

```shell
openshell logs agent-sandbox --tail
```

### View Network Activity

The sandbox supervisor logs all network decisions. Check what the agent is doing:

```shell
openshell logs agent-sandbox | grep -E "action=allow|action=deny"
```

## Inference Routing

Agents inside sandboxes can access LLM backends through the privacy-preserving `inference.local` endpoint:

```shell
openshell sandbox exec --name my-sandbox -- \
  curl -s https://inference.local/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hello"}]}'
```

The sandbox proxy intercepts `inference.local:443` and routes to configured backends without exposing real endpoint URLs to the agent.

---

!!! tip "Next Step"
    [:octicons-arrow-right-24: Configure network policies](network-policies.md)
