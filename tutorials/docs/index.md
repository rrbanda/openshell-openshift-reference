---
hide:
  - navigation
  - toc
---

<style>
.md-typeset h1 { display: none; }
</style>

<div class="hero-section" markdown>

# OpenShell on OpenShift

<p class="subtitle"><strong>OpenShell</strong> is NVIDIA's open-source agent runtime. It adds network isolation, credential masking, and audit to ANY AI agent — Claude Code, ADK, Gemini, or your own. Think of it as a security wrapper your agent runs inside.</p>

<p class="subtitle">This site shows you how to deploy it on OpenShift.</p>

<span class="badge badge-nvidia">NVIDIA OpenShell</span>
<span class="badge badge-openshift">OpenShift 4.x</span>

</div>

<div class="grid cards" markdown>

-   :material-rocket-launch:{ .lg .middle } __Quickstart (10 min)__

    ---

    Zero to running agent. One page, 10 steps, copy-paste.

    [:octicons-arrow-right-24: Start now](quickstart.md)

-   :material-book-open:{ .lg .middle } __Full Tutorial__

    ---

    Step-by-step with explanations for each component.

    [:octicons-arrow-right-24: Getting Started](getting-started/index.md)

-   :material-help-circle:{ .lg .middle } __What does OpenShell add to MY agent?__

    ---

    Interactive wizard — pick your agent, see the stack.

    [:octicons-arrow-right-24: Stack Wizard](concepts/stack-wizard.html)

</div>

---

```mermaid
flowchart LR
    CLI["openshell CLI"] -->|gRPC| GW["Gateway Pod"]
    GW -->|"Sandbox CR"| ASC["Agent Sandbox"]
    ASC -->|creates| Pod["Sandbox Pod"]
    Pod -->|"relay"| GW
```

---

<div class="grid cards" markdown>

-   :material-clock-fast:{ .lg .middle } __Set up in 5 minutes__

    ---

    Install prerequisites, deploy the gateway, create your first sandbox.

    [:octicons-arrow-right-24: Getting started](getting-started/index.md)

-   :material-shield-check:{ .lg .middle } __Policy-enforced isolation__

    ---

    Default-deny networking, L7 inspection, Landlock filesystem, seccomp.

    [:octicons-arrow-right-24: Network policies](sandboxes/network-policies.md)

-   :material-lock:{ .lg .middle } __Zero secrets in Git__

    ---

    Vault + External Secrets Operator. Pre-commit hooks block leaks.

    [:octicons-arrow-right-24: GitOps deployment](production/gitops.md)


-   :material-sitemap:{ .lg .middle } __Choose an agent stack__

    ---

    Decision guide for workflows vs agents, OpenClaw/Hermes, LangGraph/ADK, and sandbox platforms.

    [:octicons-arrow-right-24: Open the guide](agent-stack-decision-guide/index.html)

-   :material-server:{ .lg .middle } __Production ready__

    ---

    OpenShift Routes, OIDC auth, PostgreSQL HA, ArgoCD GitOps.

    [:octicons-arrow-right-24: Production guide](production/index.md)

</div>

---

## Tested On

| Component | Version |
|---|---|
| OpenShift | 4.20 (Kubernetes 1.33) |
| OpenShell Helm chart | `0.0.0-dev` |
| Agent Sandbox | v0.4.6 |
| External Secrets Operator | v1 |
| HashiCorp Vault | 1.19 (dev mode) |
