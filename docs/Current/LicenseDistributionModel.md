**Decision**  
All license assignments are performed **exclusively via group-based licensing**.  
Direct user license assignment is not permitted.

source: DEC-0008/1

---

**Decision**  
License groups are implemented as **Security groups** with **static membership**.

Source: DEC-0008/2

---

**Decision**  
Each license group represents **one license intent**.

Source: DEC-0008/3

---

**Decision**  
This lab uses **Microsoft 365 E5 as the only implemented license SKU**.

Source: DEC-0008/4

---

**Decision**  
Add-on licenses are treated identically to baseline licenses and are modeled as standard license groups (`LIC`).

Source: DEC-0008/5
Comment: Violated. has to make new decision to overwritee this rule. The license gropups are implemented as `U-LICENSE` instead of `U-LIC`.

---

**Decision**  
Personas do not receive licenses directly.  
Licenses are always derived from **group membership**.

Source: DEC-0008/6

---

**Decision**  
Administrative accounts are **not licensed by default**.

If licensing becomes strictly necessary, **Microsoft 365 E5** is used.

Source: DEC-0008/7

---

**Decision**  
No license conflict resolution logic is implemented in this lab.

Source: DEC-0008/8

---

**Decision**  
All license groups follow the naming convention:

```
U-LICENSE-<SKU>
```
Examle: U-LICENSE-SPE_E5

Source: DEC-0008/9

---

### Atomic Decision 10 – Ownership model

**Decision**  
License groups use **default tenant ownership** in this lab.

Source: DEC-0008/10

---

**Decision**  
License group creation and validation are automated using **Graph PowerShell**.

The test suite `New-MWEGroup.tests.ps1` must be updated to represent the decisions made in this document.

Source: DEC-0008/11

**Decision**  
Group membership is the **single source of truth**.

Source: DEC-0008/12

---

**Decision**  
Group-based licensing is chosen partly for **operational transparency**.

Source: DEC-0008/13

Comment: has to be removed. This is reasoning, not decision.

---

**Decision**  
Current validation is limited to:
- Group existence
- Naming convention correctness

Source: DEC-0008/14

Comment: This is for the runbook script, not for the security domain. Has to be removed.

