# Understanding Agent Architecture

How AI agents are built, run, and secured — the components, the terminology, and how they fit together.

<div class="grid cards" markdown>

-   :material-arrow-right-circle:{ .lg .middle } __See your personalized stack__

    ---

    Pick your agent, select your requirements, get your architecture in 30 seconds.

    [:octicons-arrow-right-24: Interactive Wizard](stack-wizard.html)

</div>

!!! abstract "TL;DR"
    | Layer | What it does | Example |
    |---|---|---|
    | **Model** | Reasons and decides | Claude, Gemini, GPT, Nemotron |
    | **Harness** | Makes the model useful (tools, memory, loops, filesystem) | Claude Code, ADK, Deep Agents |
    | **Runtime** | Makes it safe (isolation, policy, credential masking, audit) | OpenShell |

## The Formula

```
Agent = Model + Harness
```

A model alone is not an agent. A model takes in text and outputs text. It cannot:

- Maintain state across interactions
- Execute code or call APIs
- Access real-time knowledge
- Set up environments
- Remember anything between sessions

**The harness is everything that isn't the model.** It's the system that turns a language model from "answers questions" into "actually does work."

!!! quote "LangChain, March 2026"
    "A harness is every piece of code, configuration, and execution logic that isn't the model itself. If you're not the model, you're the harness."

---

## What a Harness Contains

Each harness component exists because there's a behavior we want from the agent that the model can't deliver alone:

| Desired behavior | What the harness adds | Why the model needs it |
|---|---|---|
| Work with real data durably | Filesystem + Git | Model only sees its context window — needs persistent storage |
| Execute actions autonomously | Bash + code execution | Model outputs text — can't run commands by itself |
| Operate safely | Sandbox + network isolation | Model-generated code could do anything — needs boundaries |
| Remember and learn | Memory files + search + MCPs | Model has no memory between calls — needs external state |
| Stay effective over long tasks | Compaction + context management | Performance degrades as context fills — needs pruning strategy |
| Complete complex multi-step work | Planning loops + verification | Model tends to stop early or drift — needs structure to persist |

```mermaid
flowchart TD
    Model["LLM (the intelligence)"]
    subgraph harness [The Harness]
        Prompt["Prompts + Instructions"]
        Tools["Tools + MCPs"]
        FS["Filesystem + Git"]
        Sandbox["Sandbox + Isolation"]
        Memory["Memory + Search"]
        Orch["Orchestration + Loops"]
        Compact["Context Management"]
        Plan["Planning + Verification"]
    end
    Model <--> harness
    harness --> Output["Agent completes real work"]
```

---

## Harness vs Runtime vs Framework

These three terms cause the most confusion. Here's the industry-standard distinction:

### Framework

**What you use to BUILD an agent.**

A framework is a build-time library — it gives you the primitives to define agents (tools, chains, graphs, agent classes) and compose them into systems.

Examples: Google ADK, LangGraph, CrewAI, Semantic Kernel

### Harness

**The complete system around the model that makes it an agent.**

The harness is the runtime application layer — orchestration loops, tools, memory, filesystem, sandbox, context management, planning. Everything the model needs to do real work.

Examples: LangChain Deep Agents (`dcode`), Claude Code, OpenClaw, OpenHands

### Agent Runtime (Infrastructure)

**The execution environment that enforces isolation, governance, and durability.**

The runtime is the infrastructure layer below the harness. It handles:

- Where the agent process runs (container, VM, sandbox)
- What it's allowed to access (network policy, filesystem restrictions)
- How state is persisted (sessions, checkpoints)
- How it's observed (traces, audit logs)

Examples: OpenShell, E2B, Modal, Fly Machines

!!! info "Key insight"
    Under LangChain's definition, the sandbox/runtime is a **component of the harness** — one piece of the larger system. Under the infrastructure industry's definition (Credal, ArXiv), it's a **separate layer**. Both views are valid — they just draw the boundary differently.

---

## How They Relate

```mermaid
flowchart TB
    subgraph you_build [What You Build]
        Agent["Your Agent Logic"]
    end
    subgraph framework [Framework Layer]
        ADK["Google ADK / LangGraph / CrewAI"]
    end
    subgraph harnessLayer [Harness Layer]
        Loop["Orchestration Loop"]
        ToolExec["Tool Execution"]
        Mem["Memory + State"]
        Ctx["Context Management"]
        Planning["Planning + Verification"]
    end
    subgraph runtimeLayer [Runtime Layer]
        Sandbox["Sandbox (OpenShell)"]
        Net["Network Policy"]
        Creds["Credential Masking"]
        Audit["Audit + Observability"]
    end
    subgraph infra [Infrastructure]
        K8s["OpenShift / Kubernetes"]
    end
    you_build --> framework
    framework --> harnessLayer
    harnessLayer --> runtimeLayer
    runtimeLayer --> infra
```

---

## Product Mapping

Aligned to Red Hat AI field positioning (July 2026): **Kagenti → OpenShell**, BYOA, and the Sandboxing for Agents use-case table. **Default policy** also matches the upstream [Supported Agents](https://docs.nvidia.com/openshell/latest/about/supported-agents.html) matrix where applicable.

### How layers compose (do not conflate)

| Layer | What it is | Owner |
|---|---|---|
| **OpenShift Sandboxed Containers (Kata)** | Hardware / dedicated-kernel isolation (L5) | OpenShift (GA layered product) |
| **OpenShell** | In-sandbox policy: Landlock, seccomp, netns, OPA L4/L7, `inference.local`, OCSF | NVIDIA OpenShell (+ Red Hat drivers) |
| **kubernetes-sigs/agent-sandbox** | Sandbox CRD lifecycle | OpenShift / OSC path |
| **MCP Gateway** | Tool OAuth2 exchange, claim-based auth (Kuadrant/Authorino) | Red Hat AI |
| **ogx / Open Responses** | Mode 2 agentic API surface | Red Hat AI |
| **MLflow + OTEL / EvalHub** | Observability & evaluation capabilities | Red Hat OpenShift AI |

**Compose:** Kata for kernel boundary ∪ OpenShell for application policy ∪ agent-sandbox for lifecycle. OpenShell does **not** replace OSC or MCP Gateway.

### Entry patterns (Kagenti → OpenShell guide)

1. **Whole-agent (Pattern 1):** `openshell sandbox create -- claude` — package agent image; no agent code changes. Field guide lists Claude Code, Codex, OpenCode, Gemini CLI.
2. **Harness-native (Pattern 2):** `harness.use_plugin("openshell")` — OpenClaw shipped; Hermes announced.

### Agents / frameworks

| Product | Category | Default OpenShell policy | Entry | NemoClaw? |
|---|---|---|---|---|
| **Claude Code** | Coding (base image) | **Full** | Pattern 1 | No |
| **GitHub Copilot CLI** | Coding (base image) | **Full** | Pattern 1 | No |
| **OpenCode** | Coding (base image) | **Partial** | Pattern 1 | No |
| **OpenAI Codex CLI** | Coding (base image) | **None** (custom policy) | Pattern 1 | No |
| **Gemini CLI** | Coding | Validated/custom image (not base matrix yet) | Pattern 1 (field guide) | No |
| **Ollama** / **Pi** | Community images | **Bundled** | Pattern 1 (`--from`) | No |
| **OpenClaw** | Assistant | Blueprint-managed | Pattern 2 | **Yes** |
| **Hermes** | Always-on | Blueprint-managed | Pattern 2 (announced) | **Yes** |
| **Deep Agents (dcode)** | Coding harness | Blueprint-managed | Pattern 2 / NemoClaw | **Yes** |
| **ADK / LangGraph / CrewAI / Strands** | BYOA frameworks | Bring-your-image | Pattern 1 | No |
| **OpenShell** | Runtime | — | — | N/A |
| **NemoClaw** | NVIDIA packaged stack | Blueprint-managed | — | N/A |

Use the [Interactive Wizard](stack-wizard.html) for isolation profiles and owner-accurate stacks.

!!! note "Identity (Kagenti convergence)"
    Kagenti shipped full SPIRE via AuthBridge (Dev Preview only — no GA). OpenShell authenticates supervisors with **gateway-minted sandbox JWTs / JWT-SVID** (SPIFFE-shaped subjects) and is **closing the SPIFFE gap**; Red Hat contributes OIDC + SPIFFE identity drivers. Platform SPIFFE/SPIRE on OpenShift layers on for cluster zero-trust — complementary, not “OpenShell already is full SPIRE.”

!!! note "Maturity"
    OpenShell is **alpha** (single-player-first). Field target: Dev/Tech Preview in RHOAI **3.5/3.6** (H2 CY2026).

---

## What ADK Provides (and Doesn't)

Google ADK is a **framework + partial harness**. It gives you build-time primitives AND some runtime capabilities:

| Harness component | ADK provides? | Details |
|---|---|---|
| Orchestration loop | Yes | Runner with event loop (yield/pause/resume) |
| Tools + MCPs | Yes | `FunctionTool`, MCP integration |
| Session persistence | Yes | `DatabaseSessionService` (PostgreSQL, Firestore, Vertex AI) |
| Memory | Yes | `MemoryBankService` |
| Multi-agent workflows | Yes | Graph-based, dynamic, collaborative workflows |
| Ambient (event-driven) | Yes | Pub/Sub, Eventarc, Cloud Scheduler triggers |
| Filesystem + Git | No | Add as custom tools |
| Code execution (bash) | No | Add as custom tool |
| Sandbox / isolation | No | Use OpenShell |
| Context compaction | No | Manage yourself |
| Ralph Loops (continue across windows) | No | Manage yourself |
| Self-verification | No | Implement via workflow nodes |

**For enterprise workflow agents** (short-lived, request/response), ADK's partial harness is usually sufficient.

**For long-running autonomous agents** (coding, research, always-on), you need additional harness components that ADK doesn't provide.

---

## Where OpenShell Fits

OpenShell provides the **application-level sandbox** in Red Hat AI's defense-in-depth model (Mode 1 whole-agent; composes with Mode 2 via ogx). Specifically:

| What OpenShell does | Layer |
|---|---|
| Network namespace + OPA proxy (L4 + optional L7 / MCP-aware) | Application runtime policy |
| Landlock + seccomp | OS-level controls inside the sandbox |
| `inference.local` routing | Credential masking / privacy router |
| OCSF v1.7.0 logging | Security audit (SIEM) — not MLflow product tracing |
| Hot-reloadable network/inference policy | Operational flexibility |

**OpenShell doesn't provide (other OpenShift AI capabilities / cluster controls do):**

- Kata / OSC hardware isolation (L5)
- MCP Gateway tool OAuth exchange (Kuadrant/Authorino)
- ogx / Open Responses Mode-2 API surface
- MLflow / OTEL, EvalHub, Garak, NeMo Guardrails (safety & evaluation portfolio)
- Orchestration loops, memory, planning (harness/framework)

**OpenShell's value (field line):** Agents are zero-trust employees — OpenShell makes sure the agent can only do what policy allows, portably from laptop (Podman) to OpenShift.

---

## Decision Guide

### "Which pieces do I need?"

=== "Short-lived workflow agent"

    Your agent handles a request, does some tool calls, returns a result.

    **You need:** Framework (ADK) + Runtime (OpenShell if calling external APIs)

    **You don't need:** Full harness, filesystem, compaction, Ralph Loops

=== "Long-running coding agent"

    Your agent works for hours writing code, running tests, pushing PRs.

    **You need:** Full harness (Deep Agents / Claude Code) + Runtime (OpenShell)

    **Or:** Framework (ADK/LangGraph) + build your own harness components + OpenShell

=== "Always-on personal assistant"

    Your agent runs 24/7, responds to messages, takes actions proactively.

    **You need:** Full harness (OpenClaw / Hermes) + Runtime (OpenShell via NemoClaw)

=== "Enterprise multi-tenant"

    Multiple teams running multiple agents with governance.

    **You need:** Framework (ADK/LangGraph) + Runtime (OpenShell with OIDC) on OpenShift projects/RBAC. OpenShift AI workspaces are a platform surface on top — not an OpenShell core feature.

---

## The Stack on OpenShift

For this reference architecture (BYOA on Red Hat AI):

```
┌─────────────────────────────────────────┐
│ Your Agent (BYOA harness / framework)   │  ← You bring this
├─────────────────────────────────────────┤
│ Red Hat OpenShift AI (the product)      │
│  · Safety & eval: Guardrails, EvalHub,  │
│    Garak, MLflow/OTEL                   │
│  · Connectivity: MCP Gateway, ogx       │
│  · OpenShell (app sandbox capability)   │  ← OPA, Landlock, seccomp,
│  · OSC / Kata (GA layered isolation)    │     inference.local, OCSF; L5
│  · agent-sandbox controller             │  ← Sandbox CR lifecycle
├─────────────────────────────────────────┤
│ OpenShift (cluster platform)            │  ← SCC/RBAC, NetworkPolicy/UDN,
│                                         │     SPIFFE/SPIRE, scheduling
└─────────────────────────────────────────┘
```

Each layer has a single responsibility. Kagenti (Dev Preview) converged into this OpenShell-centered runtime story; MCP Gateway / SPIFFE platform work continues as Red Hat AI platform layers — not as a return to Kagenti.

---

## Further Reading

- [LangChain: The Anatomy of an Agent Harness](https://www.langchain.com/blog/anatomy-of-an-agent-harness) (March 2026)
- [Credal: Agent Harness vs Agent Runtime](https://www.credal.ai/blog/agent-harness-vs-agent-runtime)
- [ArXiv: AI Runtime Infrastructure](https://www.arxiv.org/pdf/2603.00495) (2026)
- [Google ADK Documentation](https://adk.dev)
- [NVIDIA NemoClaw Documentation](https://docs.nvidia.com/nemoclaw/latest/)
- [OpenShell Documentation](https://docs.nvidia.com/openshell/latest/)
