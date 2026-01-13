# Modern Workplace Enterprise Lab
**Identity • Endpoint Lifecycle • Security • Automation**

## What this repository contains

This repository contains **three primary outputs**.

They are related, but can be consumed independently.

---

## 1. PowerShell automation module

The main deliverable is a **PowerShell module** that automates operational tasks
and **enforces explicit architectural decisions**.

- The **scripts** show how I handle automation.
- Decision current state shows what decisions are enforced by the PowerShell module.

Without decisions, implementation is just clicking — not an engineering demonstration.

The goal of the PowerShell module is to **enforce decisions and automate repeatable tasks**.

Suggested way to consume in a strict timeframe:  
Check one or two scripts, related pester tests, and review the related current state policies to see what is enforced.

---

## 2. Decision model and lab build path

The second deliverable is a **documented decision model** that demonstrates
my **architectural thinking, reasoning process, and documentation capabilities**.

My goal is not to pose as an architect, but without documented decisions I don't see the point of the lab.

- `\docs\current` shows the current state of the policies I apply with the implementation and enforce with the PowerShell module.  
- The **Decision records (DEC)** describe the history of the decisions, context, and reasoning. If all applied in series, they lead to the current documents.
- **DecisionLog.md** is an index of the decisions for easier search.

This part of the repository exists to demonstrate:
- how I structure problems,
- how I define constraints,
- where I draw boundaries,
- and what I intentionally leave out.

Suggested way to consume in a strict timeframe:  
Check one or two decision domains, then review the source decision file for context, supersedence, and reasoning.

---

## 3. Runbooks

**Runbooks (RNB)** describe how those decisions are applied in practice and log every change in the tenant.

If the runbooks are executed **in order**, and tenant-specific values (e.g. domain names, identifiers) are adjusted, the result is a copy of my tenant.

Suggested way to consume in a strict timeframe:  
Check one or two runbooks.

---

## Scope and intent

- This is a **personal, non-production lab**
- Built and maintained by a **single engineer**
- Decisions prioritise **explicit reasoning and traceability**

This repository demonstrates **how I think and automate**, not a finished enterprise blueprint.

---

## Disclaimer

This repository is provided **as-is**.

It is **not production-ready** and **not supported**.
Any use of its contents is entirely at your own risk.
The author accepts no responsibility or liability for outcomes resulting from its use.
