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

## How to read this repo
1. Start with **Scope & Assumptions** to understand what is (and is not) modeled.
2. Read the **Architecture Overview** for the “big picture”.
3. Use the **Roadmap** to see the intended build order.
4. When you reach a decision point, consult the **Decision Log** and the matching decision folder.

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
        │   ├── RNB-XXXX.json        (optional)
        │   ├── SCR-XXXX.ps1         (optional)
        └── DEC-TEMP/
            ├── DEC-TEMP.md
            ├── RNB-TEMP.md

```

## Documentation map
### Core documents (docs/)
- **ScopeAndAssumptions.md**  
  Defines the target scenario, constraints, and what is deliberately out of scope.

- **ArchiteturalOverview.md**  
  High-level components and design principles (identity-first, least privilege, device trust).

- **ThreatModelLite.md**  
  Lightweight threat model to explain what risks the lab is addressing and why.

- **roadmap.md**  
  The build sequence and milestones (what to do in what order).

- **CodingConventions.md**  
  The coding rules applied to scripts and reusable automation components.

### Decisions (docs/Decisions/)
- **DecisionLog.md**  
  A navigational index. It tells you what decisions exist and where to find them.

- **DEC-XXXX/**  
  A single decision package. The naming is **an identifier**, not a guarantee of the decision’s real-world “function”.  
  Each decision folder can include:
  - `DEC-XXXX.md` — rationale (**WHY**)
  - `RNB-XXXX.md` — execution steps / validation (**HOW**)
  - `RNB-XXXX.json` — optional parameter pack / desired-state input (**DATA**)
  - `SCR-XXXX.ps1` — optional automation script (**WITH WHAT**)
  - `APP-XXXX.md` — optional parameter reasoning (**WHY**)

- **DEC-TEMP/**  
  Templates for creating new decision packages.

## Disclaimer
This is a **personal, non-production lab** for learning, demonstration, and portfolio purposes.  
No customer data, credentials, or proprietary configurations are included. All data is mocked or synthetic.
