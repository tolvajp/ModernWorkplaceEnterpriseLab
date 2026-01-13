# Current State – License Distribution Model

This document represents the effective atomic decisions for the License distribution model
decision domain.

This document is purely declarative and contains no context, reasoning, or alternatives.
For rationale and background, consult the referenced decision files.

---

## Derived From
- DEC-0005

---

## Decisions

Atomic decision: 
All license assignments are performed exclusively via group-based licensing.  
Direct user license assignment is not permitted.
Source: DEC-0005/Atomic decision 1

---

Atomic decision:
License groups are implemented as Security groups with static membership.
Source: DEC-0005/Atomic decision 2

---

Atomic decision: 
Each license group represents one license intent.
Source: DEC-0005/Atomic decision 3

---

Atomic decision: 
This lab uses Microsoft 365 E5 as the only implemented license SKU.
Source: DEC-0005/Atomic decision 4

---

Atomic decision: 
Add-on licenses are treated identically to baseline licenses and are modeled as standard license groups (LIC).
Source: DEC-0005/Atomic decision 5

---

Atomic decision: 
Personas do not receive licenses directly.  
Licenses are always derived from group membership.
Source: DEC-0005/Atomic decision 6

---

Atomic decision: 
Administrative accounts are not licensed by default.  

If licensing becomes strictly necessary, Microsoft 365 E5 is used.
Source: DEC-0005/Atomic decision 7

---

Atomic decision: 
No license conflict resolution logic is implemented in this lab.
Source: DEC-0005/Atomic decision 8

---

Atomic decision: 
All license groups follow the naming convention:
U-LICENSE-<SKU>
Examle: U-LICENSE-SPE_E5
Source: DEC-0005/Atomic decision 9

---

Atomic decision: 
License groups use default tenant ownership in this lab.
Source: DEC-0005/Atomic decision 10

---

Atomic decision: 
License group creation and validation are automated using Graph PowerShell.

The test suite New-MWEGroup.tests.ps1 must be updated to represent the decisions made in this document.
Source: DEC-0005/Atomic decision 11

---

Atomic decision: 
Group membership is the single source of truth.
Source: DEC-0005/Atomic decision 12

---

Atomic decision: 
Group-based licensing is chosen partly for operational transparency.
Source: DEC-0005/Atomic decision 13

---

Atomic decision: Current validation is limited to:
- Group existence
- Naming convention correctness
Source: DEC-0005/Atomic decision 14