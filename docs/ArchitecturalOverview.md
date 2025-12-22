# Architecture Overview

## High-Level Architecture
This lab models a **cloud-first modern workplace architecture** with identity as the primary security control plane.

Identity, device trust, and access policies are treated as **first-class architectural components**, not afterthoughts.

---

## Core Components
- Microsoft Entra ID as the identity provider
- Conditional Access as the policy enforcement engine
- Microsoft Intune as the device authority
- Microsoft Defender for Endpoint as a security signal provider
- Microsoft Graph as the automation surface

---

## Identity-Centric Design
- No permanent administrative privileges
- Access decisions based on:
  - User identity
  - Authentication strength
  - Device compliance and risk
- Emergency access preserved through break-glass accounts

---

## Control Flow (Conceptual)
1. User attempts sign-in
2. Identity evaluated (role, risk, MFA)
3. Device state evaluated (compliance, risk)
4. Conditional Access grants or blocks access
5. Activity logged for audit and review

---

## Architectural Principles
- Least privilege
- Defense in depth
- Explicit trust boundaries
- Auditable access
- Reversible decisions
- Configuration data is kept local to runbooks and scripts. 
- A centralized configuration file is intentionally not used to avoid overengineering at the current lab scale.

---

### Automation and Execution Model

Runbooks in this lab assume a **known starting state** and transition the environment into a **known target state**.
They are executed **sequentially** and are not designed for arbitrary re-ordering or repeated execution.

As a result:
- Runbook scripts favor **deterministic execution** over full idempotency.
- Scripts may fail fast if assumptions are violated, rather than attempting to self-heal or infer state.


Where reusable automation logic or helper functions are introduced (for example in supporting scripts or utilities),
those components are expected to be **deterministic and testable**, and will be covered by **Pester tests** where appropriate.

This reflects a **controlled lab environment**, not a production automation framework.