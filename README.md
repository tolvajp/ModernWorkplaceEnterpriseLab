# Modern Workplace Enterprise Lab
**Identity • Endpoint Lifecycle • Security • Automation**

## What this is
This repository is a **greenfield Modern Workplace lab** that demonstrates an enterprise-style approach to:

- **Identity-first security** (Microsoft Entra ID, Conditional Access, PIM)
- **Endpoint management** (Microsoft Intune) and device trust signals
- **Security signals and posture** (e.g., Defender for Endpoint inputs)
- **Operational automation** using **PowerShell** and **Microsoft Graph**
- **Decision documentation** (why) and **runbooks** (how)

The lab is intentionally designed to be **readable without prior context**: start with the docs, then drill into individual decisions and runbooks.

---

## PowerShell module used by this lab
This lab includes a first-party PowerShell module (**MWE**) that implements the lab’s enforced decisions as reusable functions (for example: standardized group creation and other Graph-backed automation).

Module location:
- `src/PSmodules/MWE/` (manifest: `MWE.psd1`, module: `MWE.psm1`)

To use the lab automation, import the module (example from repo root):
```powershell
Import-Module .\src\PSmodules\MWE\MWE.psd1 -Force
```

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

A single decision domain is documented in **one DEC file** and may contain **multiple related decisions** that cannot be meaningfully separated without losing context.

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
This is a **personal, non-production lab** for learning, demonstration, and portfolio purposes.
No customer data, credentials, or proprietary configurations are included.
