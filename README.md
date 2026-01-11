# Modern Workplace Enterprise Lab
**Identity • Endpoint Lifecycle • Security • Automation**

## What this repository contains

This repository contains **two primary outputs**.

They are related, but can be consumed independently.

---

## 1. PowerShell automation module

The first deliverable is a **PowerShell module** that automates operational tasks
and **enforces explicit architectural decisions**.

- The **scripts** show how I handle automation.
- The **Decision Log and Decision records (DEC)** explain *why* those areas are automated
  and *which rules the scripts must enforce*.

Without decisions and documented reasoning,
implementation is just **clicking** —
not an engineering demonstration.

Scripts in this lab exist to **enforce decisions**, not to replace them.

---

## 2. Decision model and lab build path

The second deliverable is a **documented decision model** that demonstrates
my **architectural thinking and reasoning process — including its limits**

- The **Decision Log** describes the covered domains and intended outcomes.
- **Decision records (DEC)** describe what problems are being solved and why.
- **Runbooks (RNB)** describe how those decisions are applied in practice.

If the runbooks are executed **in order**, and tenant-specific values
(e.g. domain names, identifiers) are adjusted,
the result is a **working (but intentionally incomplete) lab environment**
that reflects the documented decisions.

This part of the repository exists to demonstrate:
- how I structure problems,
- how I define constraints,
- where I draw boundaries,
- and what I intentionally leave out.

---

## Scope and intent

- This is a **personal, non-production lab**
- Built and maintained by a **single engineer**
- Decisions prioritise **explicit reasoning and traceability**

This repository demonstrates **how I think and automate**,
not a finished enterprise blueprint.

---

## Disclaimer

This repository is provided **as-is**.

It is **not production-ready** and **not supported**.
Any use of its contents is entirely at your own risk.
The author accepts no responsibility or liability for outcomes resulting from its use.
