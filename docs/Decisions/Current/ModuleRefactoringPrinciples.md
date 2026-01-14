# Comment
Coding conventions for the PS module is mostly derived from this domain.

#Decisions:

**Decision**  
The module includes only selected functional areas.  
There is no draft, experimental, or partial functionality.

If a function exists in the module, it is considered *complete*.

**Definition of Done**  
A function is considered complete when all of the following are true:

- Comment-based help is present (Synopsis and at least one example)
- Input validation is explicit and fail-fast
- Behavior is deterministic for a given input and tenant state
- Errors are terminating and not silently ignored
- Output is pipeline-compatible and object-based
- Supports `-WhatIf` / `ShouldProcess` semantics where the operation results in
  state changes

Source: DEC-0007/1

  ---

  **Decision**  
Public functions represent **operational domains** of the module.

Internal implementation details are encapsulated in non-exported helper
functions and may evolve freely.

Source: DEC-0007/2

---

**Decision**  
Internal refactoring is explicitly allowed and expected as the module evolves.

Public function contracts are treated as stable and intentional.
Any breaking change to a public contract must be reflected through versioning.

Source: DEC-0007/3

---

**Decision**  
The module does not read configuration files or parse external data formats.

All required input is provided via parameters or structured objects supplied by
the caller.

Source: DEC-0007/4

---

**Decision**  
`Write-Host` is prohibited in all module code.

Approved output mechanisms are:
- Structured object output
- `Write-Verbose`
- `Write-Information`
- `Write-Warning`
- `Write-Error`

Source: DEC-0007/5

---

**Decision**
The module follows a fail-fast error handling model.
All errors are terminating.

Function behaviour is defined by a strict contract, of which the PowerShell verb is a mandatory part.
Functions are divided into two categories:

Imperative (lifecycle) functions use `New-` and `Remove-` verbs.
If a `New-*` function is executed and the target resource already exists, the function terminates with an error.
If a `Remove-*` function is executed and the target resource does not exist, the function terminates with an error.
Re-running lifecycle functions is considered a logical pipeline error.

Desired-state (convergent) functions use `Set-`, `Ensure-`, `Enable-`, `Disable-`, and `Assign-` verbs.
These functions enforce a declared desired state.
If the desired state is already met, the function performs no changes and returns success.
If the desired state is not met, the function converges the state where possible.
If convergence is not possible or validation fails, the function terminates with an error.

Verb naming is normative in this module: the verb defines the behavioural contract and expected idempotent behaviour.

Any introduction of a new verb must be documented and maintained in the Coding Conventions.

Source: DEC-0007/6

---

**Decision**  
The module does not establish authentication contexts.

All public functions assume that authentication and authorization have already
been performed by the caller.
Required permissions and scopes are treated as preconditions.

If required permissions are missing, functions terminate immediately.

Source: DEC-0007/7

---

**Decision**  
Secrets and passwords are not permitted anywhere in the module.

- No hard-coded secrets.
- No embedded credentials.
- No password material in code, configuration, examples, comments, or test data.
- If a secret is required operationally, it MUST be supplied externally by the caller via an approved secure mechanism.

Source: DEC-0007/8

---

**Decision**  
The entire module MUST be covered by automated Pester tests.

- All public functions MUST have test coverage.
- Tests MUST be runnable in CI and locally.
- New or changed functionality MUST include corresponding test updates.

Source: DEC-0007/9

---

**Decision**  
All public functions and parameters follow strict naming conventions:

- Functions use approved PowerShell verbs and **Verb-Noun** naming.
- Function names and parameter names use **PascalCase**.
- Local variables use **camelCase**.

Source: DEC-0007/10

---

**Decision**  
The module enforces terminating errors by default.

- The module sets `$ErrorActionPreference = 'Stop'` at each public and helper function.
- Errors MUST NOT be silently ignored, downgraded, or suppressed.

Source: DEC-0007/11

---

**Decision**  
All functions require only the minimum necessary Graph/API permissions.

- Required permissions/scopes are treated as explicit preconditions of each function.
- Functions MUST NOT request broader scopes than necessary to perform their operation.

Source: DEC-0007/12

---

**Decision**

All meaningful command invocations in the MWE module MUST be executed through Invoke-MWECommand for consistent verbose observability.

Commands that perform I/O, query tenant state, or change state (Graph cmdlets, Graph REST requests, internal helper functions with side effects) MUST be invoked via Invoke-MWECommand.

Pure PowerShell plumbing operations (for example: Where-Object, Select-Object, Sort-Object, Out-Null, Get-Date, Start-Sleep, Write-*) MUST NOT be wrapped.

If a command already uses a splat, it MUST be passed unchanged to Invoke-MWECommand; if it does not, a splat MUST be created in the calling function scope.

Invoke-MWECommand and Invoke-NWEWithLazyObject MUST NOT be wrapped (they are the logging/observability primitives).

Source: DEC-0007/13

---


**Decision**
The module follows a strict versioning policy.

Major version increments when a public function surface is broken.
This includes changes where an existing parameter set, parameter behavior, or invocation pattern no longer works as previously defined.

Minor version increments when new public functionality is introduced.
This includes adding new public functions or extending existing functions with new, backward-compatible capabilities.

Patch version increments when no new public functions or functionality are introduced.
Patch releases are limited to internal refactoring, bug fixes, documentation updates, or test changes that do not alter public behavior.

Source: DEC-0007/14
