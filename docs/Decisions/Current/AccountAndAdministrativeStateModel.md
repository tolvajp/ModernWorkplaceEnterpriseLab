# Current State – Account and Administrative Role Model

This document represents the effective atomic decisions for the Account and administrative role model
decision domain.

This document is purely declarative and contains no context, reasoning, or alternatives.
For rationale and background, consult the referenced decision files.

---

## Derived From
- DEC-0002

---

## Decisions

The tenant will use a strictly separated account model consisting of:

- Standard user accounts for daily productivity
- Dedicated administrative accounts for privileged operations
- Emergency access (break-glass) accounts for recovery scenarios

Administrative privileges will never be exercised using standard user accounts.
Each account type has a distinct purpose, risk profile, and security treatment.
