# Current State – Group Taxonomy and Naming Rules

This document represents the effective atomic decisions for the Group taxonomy and naming rules
decision domain.

This document is purely declarative and contains no context, reasoning, or alternatives.
For rationale and background, consult the referenced decision files.

---

## Derived From
- DEC-0004

---

## Decisions

Atomic decision: 
All managed group names follow a tokenized, extensible structure
Source: DEC-0004/Atomic decision 1

---

Atomic decision: 
Allowed characters are explicitly defined
Source: DEC-0004/Atomic decision 2

---

Atomic decision: 
Whitespace and disallowed characters are removed
Source: DEC-0004/Atomic decision 3

---

Atomic decision: 
`mailNickname` equals the normalized group name. It should not be longer than 64 char.
Source: DEC-0004/Atomic decision 4

---

Atomic decision: 
Group descriptions are mandatory and explicit
Source: DEC-0004/Atomic decision 5

---

Atomic decision: 
Managed groups are created exclusively by automation
Source: DEC-0004/Atomic decision 6

---

Atomic decision: 
Group creation logic must be modular and extensible
Source: DEC-0004/Atomic decision 7