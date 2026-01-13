# Current State – Conditional Access Model

This document represents the effective atomic decisions for the Conditional Access Model
decision domain.

This document is purely declarative and contains no context, reasoning, or alternatives.
For rationale and background, consult the referenced decision files.

---

## Derived From
- DEC-0009

---

## Decisions

Atomic decision:
Conditional Access MUST NOT be used to implement, replace, or duplicate
authorization logic.

- CA MUST NOT be used to decide whether an identity is entitled to access a resource.
- Authorization is handled exclusively via roles, groups, and permissions.
- CA evaluates only whether the access attempt is sufficiently secure, not whether it is permitted.
Source: DEC-0009/Atomic decision 1

Atomic decision:
Multi-Factor Authentication (MFA) is treated as a condition within the CA model.

- CA expresses which MFA assurance level is required
- MFA policy defines which authentication methods satisfy that assurance
- CA policy enforces this in combination with other security inputs
Source: DEC-0009/Atomic decision 2

Atomic decision:
The CA model defines an explicit baseline security posture that is:
- implementable
- the minimum acceptable posture for access (no identity may go below it)
- only maintainable or strengthenable (never weakened)
Source: DEC-0009/Atomic decision 3

Atomic decision:
Missing, unknown, or unavailable security signals MUST not be used to relax
security requirements.

- Unknown = untrusted
- A lack of information cannot reduce assurance
Source: DEC-0009/Atomic decision 4

Atomic decision:
When a high-confidence malicious activity signal is present, access is blocked
unconditionally for all non-break-glass identity types.

- Applies to:
  - standard users
  - administrative users
  - service / automation identities
- Independent of:
  - MFA state
  - device context
  - location
Source: DEC-0009/Atomic decision 5

Atomic decision:
Location and network context may only contribute to increased strictness when
combined with other risk signals. Location is never used:
- as a standalone trust signal
- to relax security requirements
Source: DEC-0009/Atomic decision 6

Atomic decision:
Conditional Access is treated as a sign-in gate:
- Decisions are made at authentication time
- Session-level and continuous enforcement are out of scope for this model
Source: DEC-0009/Atomic decision 7

Atomic decision:
The CA model applies a global, application-agnostic baseline.
Application-specific strictness is allowed only as an explicit, justified exception.
Source: DEC-0009/Atomic decision 8

Atomic decision:
Authentication methods/protocols that cannot satisfy the baseline security posture
are considered incompatible by default.
Source: DEC-0009/Atomic decision 9

Atomic decision:
The CA model requires operational visibility for significant security events.
Source: DEC-0009/Atomic decision 10

Atomic decision:
Automation and service identities are within the conceptual scope of CA.

Multi-Factor Authentication is not applicable to automation and service identities.

However, the detailed CA model and implementation for automation identities are
explicitly out of scope for this lab.
Source: DEC-0009/Atomic decision 11

Atomic decision:
Exceptions to the CA model are permitted only with:
- documented business justification
- explicit approval
- defined expiration
- regular review
Source: DEC-0009/Atomic decision 12
