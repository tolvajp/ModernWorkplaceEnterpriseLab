# Modern Workplace Enterprise Lab
**Identity • Endpoint Lifecycle • Security • Automation**

## What this is (and what it is not)

This repository is a **personal, non-production Modern Workplace lab** created and maintained by a **single engineer**, without formal peer review.

It is **not a polished technical demo**, reference architecture, or production-ready blueprint.

The primary purpose of this lab is to **demonstrate my logical and architectural decision-making process**:
how I reason about identity, endpoint management, security boundaries, and automation under realistic constraints such as
limited time, incomplete information, and evolving requirements.

The documented decisions were often made under **time pressure** and are intentionally kept **explicit rather than exhaustively optimised**.
They do not represent the maximum technical depth I would apply in a fully resourced, multi-review enterprise environment.

This repository focuses on **how decisions are framed, constrained, and connected** — not on showcasing perfect or final implementations.

---

## What this lab demonstrates

This repository is a **greenfield Modern Workplace lab** that demonstrates an enterprise-style approach to:

- **Identity-first security** (Microsoft Entra ID, Conditional Access, PIM)
- **Endpoint management** (Microsoft Intune) and device trust signals
- **Security signals and posture** (e.g. Defender for Endpoint inputs)
- **Operational automation** using **PowerShell** and **Microsoft Graph**
- **Decision documentation** (why) and **runbooks** (how)

The lab is intentionally designed to be **readable without prior context**:
start with the documentation, then drill into individual decision domains and runbooks.

---

## PowerShell module used by this lab

This lab includes a first-party PowerShell module (**MWE**) that implements the lab’s enforced decisions as reusable functions
(for example: standardized group creation and other Graph-backed automation).

Module location:
- `src/PSmodules/MWE/`
- Manifest: `MWE.psd1`
- Module: `MWE.psm1`

To use the lab automation, import the module (example from repo root):

    Import-Module .\src\PSmodules\MWE\MWE.psd1 -Force

If you run Pester tests, they import the module from the manifest as well.

---

## Decision model used in this lab

This lab uses a **decision-domain model** instead of a strict “one decision per file” approach.

### Decision Domain

A **Decision Domain** represents a logically coherent area of architecture or design.

Examples:
- Group-based access and licensing
- Administrative role and privilege modelling
- Device trust and compliance signals

A single decision domain is documented in **one DEC file** and may contain **multiple related decisions**
that cannot be meaningfully separated without losing context.

In other words:
> A decision domain answers: *“What area are we deciding about?”*

---

### Atomic Decision

An **Atomic Decision** is a single, indivisible design choice made within a decision domain.

Characteristics:
- It expresses **one clear rule or constraint**
- It can be reasoned about independently
- It may depend on earlier atomic decisions in the same file

Examples:
- “All access intent is expressed through group membership”
- “No direct user role assignments are allowed”
- “Role assignment mode (eligible or permanent) is invariant”

Each atomic decision may include:
- Context (scope, reasoning, constraints)
- Alternatives considered (when relevant)
- Notes or implications

Not all atomic decisions require the same level of explanation.

An atomic decision answers:
> *“What exact choice are we making here?”*

---

### Why this model is used

This approach reflects how real-world architecture decisions are made:

- Decisions are **clustered by topic**, not artificially split
- Closely related choices are reasoned about together
- Implementation (runbooks/scripts) exists **only when meaningful**

Each decision domain may have:
- One or more **runbooks** (how the decision is executed or validated)
- Zero or more **scripts** (when automation makes sense)

Not every decision results in executable actions.

---

### Conceptual analogy to enterprise delivery models

For orientation only, the structure used in this lab can be loosely compared to how work is often organised in larger enterprises.

This is an **analogy**, not a one-to-one mapping:

- A **Decision Domain** is comparable to an *epic*:
  a larger, logically cohesive problem space that is explored as a whole.

- **Atomic Decisions** are comparable to *design or project-level decisions*:
  individual, explicit choices made within that domain.

- A **Runbook (RNB)** is comparable to a *change set*:
  a structured collection of related changes that belong together and are executed as a unit.

- Individual scripts or manual steps within a runbook are comparable to *individual changes*.

This analogy exists purely to help readers familiar with enterprise environments orient themselves.
It is not intended to mirror formal ITIL or change-management processes.

This lab intentionally optimises for:
- a single engineer,
- limited time,
- explicit reasoning,
- and demonstrable thinking patterns.

Passing a formal **change review** process is **not** a goal of this repository.

---

## How to read this repo

1. Start with **Scope & Assumptions** to understand what is (and is not) modeled.
2. Read the **Architecture Overview** for the big picture.
3. Use the **Roadmap** to see the intended build order.
4. For a specific topic, open the corresponding **Decision Domain (DEC-XXXX)**.
5. Review the **Atomic Decisions** inside the DEC file.
6. If present, follow the associated **Runbook (RNB)**.

---

## Repository structure

.
├── README.md
└── docs/
    ├── ScopeAndAssumptions.md
    ├── ArchiteturalOverview.md
    ├── ThreatModelLite.md
    ├── roadmap.md
    ├── CodingConventions.md
    └── Decisions/
        ├── DecisionLog.md
        ├── DEC-XXXX/
        │   ├── DEC-XXXX.md
        │   ├── RNB-XXXX.md
        │   ├── RNB-XXXX.json
        │   ├── SCR-XXXX.ps1
        │   └── artifacts/
        └── DEC-TEMP/
            ├── DEC-TEMP.md
            ├── RNB-TEMP.md
            ├── SCR-TEMP.md

---

## Disclaimer

This repository is a **personal, non-production lab** intended for learning, exploration, and professional demonstration.

- It reflects the work of a **single engineer**, without formal peer review.
- Decisions prioritise **explicit reasoning and traceability** over completeness or optimisation.
- The content is **not intended for direct production use**.
- **Any use of the material in this repository is entirely at the user’s own risk.  
  The author accepts no responsibility or liability for any outcomes resulting from its use.**

No customer data, credentials, or proprietary configurations are included.
