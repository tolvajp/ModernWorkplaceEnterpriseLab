# Threat Model (Lite)

## Purpose
This document captures a **lightweight threat model** focused on identity-centric risks.

It is not a formal STRIDE exercise, but a practical enumeration of common enterprise threats and mitigations.

---

## Key Threats Considered

### Credential Theft
- Mitigation:
  - MFA
  - Conditional Access
  - Legacy authentication blocked

### Excessive Privileges
- Mitigation:
  - PIM (just-in-time roles)
  - No permanent admins
  - Access reviews

### Device Compromise
- Mitigation:
  - Device compliance policies
  - Defender for Endpoint risk signals
  - Conditional Access enforcement

### Tenant Lockout
- Mitigation:
  - Dedicated break-glass accounts
  - Explicit CA exclusions
  - Documented recovery process

---

## Residual Risk
- Trial tenants lack long-term monitoring maturity
- User behavior risks are simplified in lab scenarios

---

## Intent
Threat modeling is used to **justify controls**, not to eliminate all risk.