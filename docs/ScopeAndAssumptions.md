# Scope & Assumptions

## Purpose
This lab is a **personal, enterprise-inspired Modern Workplace environment** built for learning and demonstration.
It prioritizes **architecture, operational thinking, and reproducibility** over feature completeness.

## Target scenario
A mid-size organization with:
- Cloud-first strategy using Microsoft 365
- Entra ID as the identity boundary
- Intune-managed Windows endpoints as the primary device fleet
- Conditional Access used to enforce authentication and device trust

## In scope
- Identity architecture and account model (admin separation, emergency access)
- Conditional Access strategy and baseline policies
- Endpoint enrollment and compliance baselines in Intune
- Security signal integration (where available)
- Automation patterns using PowerShell and Microsoft Graph
- Documentation discipline: decisions, runbooks, and validation

## Out of scope
- SOC operations, SIEM/SOAR pipelines, incident response playbooks
- Formal enterprise change-management processes
- Multi-team ownership, complex delegation models, or large-scale org politics
- Full production hardening for every control (this is a lab)

## Scope Note

This architecture represents a **lab-scale implementation** executed by a
single engineer.

Organizational elements such as peer review, SOC operations, formal change
management, and multi-team ownership are intentionally out of scope and would
materially increase complexity and delivery timelines in a real enterprise.


## Assumptions
- Single engineer executes changes sequentially using runbooks
- The lab maintains a “known state” at each milestone
- Scripts avoid storing secrets in the repo
- Tenant-specific identifiers are parameterized (JSON or script parameters)

## Non-goals
- Becoming a complete reference implementation for all Microsoft 365 features
- Optimizing for exam objectives over operational realism
