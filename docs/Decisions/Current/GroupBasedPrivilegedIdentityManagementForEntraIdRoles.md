# Current State – Group-based Privileged Identity Management for Entra ID Roles

This document represents the effective atomic decisions for the Group-based Privileged Identity
Management (PIM) for Entra ID Roles decision domain.

This document is purely declarative and contains no context, reasoning, or alternatives.
For rationale and background, consult the referenced decision files.

---

## Derived From
- DEC-0006

---

## Decisions

Atomic decision:
- All permanent Entra ID directory role assignments are mediated exclusively through groups.
- No Entra role is ever assigned directly to a user.
- This rule applies strictly to non-expiring (baseline) role eligibility or activation.
Source: DEC-0006/Atomic decision 1

Atomic decision:
**In Scope**
- Microsoft Entra ID directory roles
- Permanent (non-expiring) role eligibility or activation
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
Source: DEC-0006/Atomic decision 2

Atomic decision:
- One group represents exactly one Entra role
- A group is bound to either an Eligible or an Active assignment — never both
- For each role, an explicit decision is made whether it is eligible (PIM-protected) or permanently active
Source: DEC-0006/Atomic decision 3

Atomic decision:
- Roles protected by PIM are protected for all users, without exception
- Group membership never grants immediate privilege unless the role is explicitly defined as Active
- PIM activation is mandatory to transition from eligibility to effective privilege
Source: DEC-0006/Atomic decision 4

Atomic decision:
- In this lab, group membership governance is not implemented
- If users need any roles, they get Global Administrators by definition (see DEC-0001)
Source: DEC-0006/Atomic decision 5

Atomic decision:
- All Entra role group memberships must be reviewed at least every 6 months
- The review must confirm that:
  - The user still requires the role
  - The role still aligns with the user’s responsibilities
Source: DEC-0006/Atomic decision 6

Atomic decision:
- Security groups only
- Static membership only
Source: DEC-0006/Atomic decision 7

Atomic decision:
All role groups follow this strict pattern:

U-ENTRAROLE-<RoleName>-<ELIGIBLE | ACTIVE>

Rules:
- Exactly one group per role
- Exactly one state (ELIGIBLE or ACTIVE)
- Naming must fully describe role and privilege state
Source: DEC-0006/Atomic decision 8
