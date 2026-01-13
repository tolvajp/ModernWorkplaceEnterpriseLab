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

Without decisions implementation is just clicking — not an engineering demonstration.

The goal of powershell module is to **enforce decisions and automate repeteable tasks**.

**Suggested way to consumme in strict timeframe: Check one or two scipts, and check the current folder for related policies for the domain.**

---

## 2. Decision model and lab build path

The second deliverable is a **documented decision model** that demonstrates
my **architectural thinking, reasoning process and docummentation capabilities**

My goal is not to pose as an architect, but without documented decisions I don't see the point of the lab.

- \docs\current shows the current state of the policies I apply with the implementation, enforce with the PowerShell Module.  
- The **Decision records (DEC)** describes the history of the decisions, contex, and reasoning. If all applied in series it leads to current docs.
- **DecisionLog.md** is an index of the decisions for easier search.

This part of the repository exists to demonstrate:
- how I structure problems,
- how I define constraints,
- where I draw boundaries,
- and what I intentionally leave out.

**Suggested way to consume in strict time frame: Check one or two decision domain, select one or two atomic decision, and check it in the decision files for consistency, reasoning, scope, etc.**

## 3. Runbooks

**Runbooks (RNB)** describe how those decisions are applied in practice, logs every change in the tenant.

If the runbooks are executed **in order**, and tenant-specific values (e.g. domain names, identifiers) are adjusted, the result is a a copy of my tenant.

**Suggested way to consume in strict time frame: cheeck one or two runbooks.**

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
