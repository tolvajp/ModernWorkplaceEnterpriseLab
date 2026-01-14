# Architectural Overview

## Core idea

The architecture is **decision-first**.

Implementation exists to enforce decisions, not the other way around.

## Key layers

- Decision Trail (DEC)
- Current State Models
- Automation (PowerShell module)
- Validation (Pester tests)

Architecture evolves by adding or superseding decisions, not by ad-hoc refactoring.
