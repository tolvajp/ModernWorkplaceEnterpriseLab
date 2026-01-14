**Decision**  
- **All permanent Entra ID directory role assignments are mediated exclusively through groups**.
- **No Entra role is ever assigned directly to a user**.
- This rule applies strictly to **non-expiring (baseline) role eligibility or activation**.

source: DEC-0006/1

**Decision**

**In Scope**
- Microsoft Entra ID *directory roles*
- **Permanent (non-expiring) role eligibility or activation**
- Group-based PIM eligibility and activation
- Role activation policy (time-bound, MFA, justification)

**Out of Scope**
- Project-based or temporary role assignments
- Access Packages (Entitlement Management)
- Azure RBAC (subscription / resource group roles)
- Workload-specific roles (Exchange, Defender, etc.)
- Conditional Access configuration
- MFA technology selection
- Monitoring and SIEM integration
- BreakGlass Accounts

Source: DEC-0006/2
Comment: Has to be removed. This is scope, not decision.

---

**Decision**
- **One group represents exactly one Entra role**
- A group is bound to **either** an *Eligible* **or** an *Active* assignment — never both
- For each role, an explicit decision is made whether it is eligible (PIM-protected) or permanently active

Source: DEC-0006/3

---

**Decision**
- Roles protected by PIM are protected **for all users**, without exception
- Group membership **never grants immediate privilege** unless the role is explicitly defined as Active
- PIM activation is mandatory to transition from eligibility to effective privilege

Source: DEC-0006/4

---

**Decision**
- In this lab, group membership governance is **not implemented**
- If users need any roles, they get Global Administrators by definition (see DEC-0001)

**Real-world recommendation (non-implemented):**
- Group ownership should be PIM-protected
- Membership changes should require approval
- Separation of duties between role eligibility management and role usage should be enforced

Source: DEC-0006/5

---

**Decision**
- **All Entra role group memberships must be reviewed at least every 6 months**
- The review must confirm that:
  - The user still requires the role
  - The role still aligns with the user’s responsibilities

Source: DEC-0006/6

  ---

**Decision**
- **Security groups only**
- **Static membership only**

**Rationale**  
Dynamic group membership introduces implicit, attribute-driven privilege changes that are difficult to reason about and audit.  
Static security groups preserve deterministic behavior and make privilege state explicit.

Source: DEC-0006/7

---

**Decision**

All role groups follow this strict pattern:

U-ENTRAROLE-<RoleName>-<ELIGIBLE | ACTIVE>


Rules:
- Exactly one group per role
- Exactly one state (ELIGIBLE or ACTIVE)
- Naming must fully describe role and privilege state

Source: DEC-0006/8
