# Current State – Authentication Baseline: MFA Model

This document represents the effective atomic decisions for the Authentication Baseline: MFA Model
decision domain.

This document is purely declarative and contains no context, reasoning, or alternatives.
For rationale and background, consult the referenced decision files.

---

## Derived From
- DEC-0008

---

## Decisions

Atomic decision:
MFA is a baseline requirement for interactive sign-ins
Source: DEC-0008/Atomic decision 1

Atomic decision:
MFA applies to all interactive user identities
Source: DEC-0008/Atomic decision 2

Atomic decision:
MFA methods are categorized by strength and allowed usage
Source: DEC-0008/Atomic decision 3

Atomic decision:
Administrative MFA requirements must not be relaxed
Source: DEC-0008/Atomic decision 4

Atomic decision:
Device context is a valid input signal, not a substitute
Source: DEC-0008/Atomic decision 5

Atomic decision:
Unknown or missing device context is untrusted
Source: DEC-0008/Atomic decision 6

Atomic decision:
Break-glass accounts are an explicit MFA exception
Source: DEC-0008/Atomic decision 7

Atomic decision:
Phishing-resistant, multi-factor methods satisfy MFA
Source: DEC-0008/Atomic decision 8

Atomic decision:
Passwordless multi-factor authentication is MFA by definition
Source: DEC-0008/Atomic decision 9

Atomic decision:
Legacy authentication is incompatible with the MFA baseline
Source: DEC-0008/Atomic decision 10

Atomic decision:
Authentication scoping is defined through identity categorization groups
Source: DEC-0008/Atomic decision 11
