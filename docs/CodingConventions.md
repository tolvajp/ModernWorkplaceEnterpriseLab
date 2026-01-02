## PowerShell Module Coding Conventions

1. **Modules are APIs**  
   Public functions define a stable contract; breaking changes require a major version bump.

2. **Approved Verb–Noun Naming**  
   All public functions use approved PowerShell verbs and PascalCase names; parameters are PascalCase, local variables camelCase.

3. **Verb Defines Behavior**  
   `New-*` and `Remove-*` are imperative and fail if the target already exists or is missing; `Set-*`, `Ensure-*`, `Enable-*`, `Disable-*`, `Assign-*` are idempotent and converge state.

4. **Idempotency by Default**  
   Re-running a desired-state function with the same input must result in the same tenant state without errors.

5. **Explicit Error Handling**  
   All failures are terminating errors; silent ignores, retries without intent, or downgraded warnings are not allowed.

6. **No Side Effects Outside Parameters**  
   Modules do not read configuration files, prompt for input, or authenticate; all inputs are explicit and passed by the caller.

7. **ShouldProcess for State Changes**  
   Any function that modifies state must support `ShouldProcess` and respect `-WhatIf` / `-Confirm`.

8. **Structured Output and Logging**  
   Functions return objects, not formatted strings; `Write-Host` is forbidden—use standard PowerShell output and logging streams.

9. **Secrets and Permissions**  
   Secrets are never stored or passed in code; missing permissions or scopes result in immediate terminating errors.

10. **Help and Test Coverage**  
    Every public function includes comment-based help with at least one example and is covered by Pester tests.

Further architectural intent and rationale for these rules are defined in **DEC-0007**.
