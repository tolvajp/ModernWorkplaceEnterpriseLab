## Coding Conventions

1. **Verb–Noun naming for scripts and functions**  
   Use Microsoft-approved verbs (Get, Set, New, Remove, Test, Invoke).

2. **PascalCase for functions and parameters**  
   Example: `Get-InactiveDevicesReport -InactiveDays 90`.

3. **camelCase for variables**  
   Use clear, descriptive variable names.

4. **Consistent formatting and indentation**  
   Use 4 spaces and one logical action per line.

5. **Explicit error handling**  
   Use `-ErrorAction Stop` for critical operations.

6. **Least-privilege principle**  
   Request only the minimum required permissions (Graph / API scopes).

7. **No hard-coded secrets or identifiers**  
   Use parameters, environment variables, or secure stores.

8. **Idempotent behavior where applicable**  
   Runbook execution is **deterministic** and assumes a known, sequential lab state.  
   Reusable automation scripts and helper functions are **idempotent** and tested with **Pester** where appropriate.

9. **Readable and predictable output**  
   Return objects where possible; avoid `Write-Host` for data output.

10. **Basic automated validation**  
    Use Pester tests for reusable critical scripts.