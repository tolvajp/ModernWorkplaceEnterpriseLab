# Decision-Trail and Current State Model

## Purpose

This document defines the decision-trail model and the current state model used in this repository.

It specifies how decisions are recorded, evolved, superseded, and how the effective rules are represented at any point in time.

---

## Core Separation

### Decision Files (DEC)

Decision files are the authoritative source of:
- context
- reasoning
- trade-offs
- alternatives
- change intent

Decision files explain why and how decisions are made or changed.
Decision files may be superseded over time.

---

### Current State Documents (CS)

Current state documents are **purely declarative**.

They contain:
- no context
- no explanation
- no reasoning
- no alternatives
- no trade-offs

If the rationale behind a rule is required, the referenced decision file must be consulted.

---

## Reading Paths

### Decision-Trail to Current State

Reading the relevant decision files allows reconstruction of the current state together with the reasoning trail.

### Current State to Decision-Trail

Reading the current state alone provides the effective rules in force after all supersedence has been applied.
Reasoning is obtained by following references to the decision files.

---

## Decision Domains

- Decision content is organized by decision domain.
- Decision domains remain stable over time.
- Each decision domain has exactly one current state document.
- Atomic decisions from different domains must not be mixed in the same current state document.

Examples:
- Identity
- Conditional Access
- MFA

---

## A Decision File May

1. Introduce a new decision domain.
2. Add, revoke, or change atomic decisions within an existing decision domain.

---

## Current State Definition

A current state document represents the effective list of atomic decisions for **a single decision domain**.

Rules:
- Atomic decisions are copied **verbatim** (character-for-character) from the decision file.
- Atomic decisions are **not assigned new IDs** in the current state.
- Each atomic decision includes a reference to its source decision file and atomic decision number.

---

## Current State Template

This document is derived from:
- DEC-000x
- DEC-000y

Decisions:
- <atomic decision text copied verbatim>
  From: DEC-000x, Atomic Decision <n>
- <atomic decision text copied verbatim>
  From: DEC-000y, Atomic Decision <m>

---

## Atomic Decision Lifecycle

### Introduction

When a decision file introduces atomic decisions for a domain, those atomic decisions are added directly to the current state.

### Change

If a decision file changes an atomic decision:
- the old atomic decision is removed from the current state
- the new atomic decision is added to the current state

### Revocation

If a decision file revokes an atomic decision:
- the atomic decision is removed from the current state
- no replacement is required

---

## Supersedence Rules

- Partial supersedence is not allowed: an atomic decision is either fully effective or not present in the current state.
- Any textual change, including a single word, requires a new atomic decision.
- Superseded atomic decisions must not appear in the current state.

---

## Consistency Rules

- An atomic decision enters the current state through exactly one decision file.
- Each atomic decision may appear only once in the current state.
- The current state must not contain duplicates or contradictions.

---

## Change Narrative Placement

- Decision files describe what atomic decision is changed (from what to what), with context and reasoning.
- Current state documents contain only the resulting effective atomic decisions.
