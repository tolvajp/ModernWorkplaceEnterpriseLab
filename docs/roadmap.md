# Roadmap

**Goal:** Build an enterprise-inspired Modern Workplace lab in a deterministic, documented way.  
**Focus:** Identity, device lifecycle, policy enforcement, security signals, automation.  
**Approach:** The lab progresses decision-by-decision. Each milestone defines authority, trust boundaries, and lifecycle transitions rather than implementation checklists.

---

## Milestone 0 — Repository baseline
- Establish the documentation skeleton under `docs/`
- Define structural conventions for decisions, runbooks, validation, and appendices
- Ensure the lab can be reasoned about and reviewed independently of tooling

---

## Milestone 1 — Tenant foundation (identity baseline)
- Define tenant scope, naming conventions, and core assumptions
- Establish the account model:
  - standard user accounts
  - daily administrative accounts
  - emergency access accounts
- Define identity trust boundaries and administrative separation

---

## Milestone 2 — Conditional Access baseline (identity enforcement)
- Establish a minimal Conditional Access baseline for:
  - MFA enforcement
  - administrative protection
  - legacy authentication restriction
- Explicitly document exclusions, emergency access handling, and rollback paths
- Treat Conditional Access as an enforcement layer, not a feature configuration

---

## Milestone 3 — Device identity and management authority (Intune)
- Define what constitutes a managed device in the tenant
- Establish device registration and enrollment assumptions
- Define ownership and join models:
  - corporate vs. personal
  - user-associated vs. organization-controlled devices
- Clarify the relationship between Entra ID device objects and Intune management authority

---

## Milestone 4 — Configuration authority and security baselines (Intune)
- Establish configuration authority using Intune policies
- Define security baselines versus custom configuration profiles
- Handle configuration conflicts and drift scenarios explicitly
- Document which settings are intentionally not enforced and why

---

## Milestone 5 — Application definition and device readiness
- Define the application model for managed devices
- Establish required versus optional application sets
- Define application detection and readiness assumptions
- Treat application presence and health as part of device usability and trust

---

## Milestone 6 — Update management and remediation authority
- Define update authority for managed devices and applications
- Establish OS and application update cadence
- Define reboot behavior and remediation expectations
- Treat update state as an operational health and trust signal

---

## Milestone 7 — Device compliance as a trust signal
- Define compliance rules as signal aggregation, not goals
- Establish grace periods, failure handling, and edge cases
- Document false positives and non-blocking non-compliance scenarios
- Prepare compliance output for access enforcement consumption

---

## Milestone 8 — Security signals and access coupling
- Tie device compliance and risk signals to Conditional Access
- Define access behavior for known-good and known-bad device states
- Explicitly document exception, emergency, and recovery scenarios
- Validate enforcement behavior across identity, device, and access layers

---

## Milestone 9 — Autopilot provisioning and lifecycle verification
- Introduce Autopilot only after device management is fully defined
- Use Autopilot to orchestrate provisioning of pre-defined policies and applications
- Treat first boot as an end-to-end lifecycle and trust verification step
- Validate that a clean device reaches a known, compliant, and usable state deterministically

---

## Milestone 10 — Automation and operational routines
- Establish repeatable operational patterns using Microsoft Graph
- Automate validation, reporting, and state verification
- Ensure automation reinforces determinism, auditability, and controlled change

---

## Definition of done (lab-level)
- The lab can be rebuilt from scratch by following documented runbooks
- Decisions clearly capture rationale, trade-offs, and rollback considerations
- Device lifecycle states are deterministic and reviewable
- Autopilot successfully validates end-to-end readiness
- Automation artifacts are predictable, reviewable, and non-destructive