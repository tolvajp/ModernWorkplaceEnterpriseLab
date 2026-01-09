function New-MWE<Thing> {
<#
.SYNOPSIS
Creates and provisions a <Thing> according to MWE standards.

.DESCRIPTION
Public entry point for provisioning a <Thing> in the Modern Workplace Enterprise (MWE) lab.

This function:
- Acts as the API surface of the module
- Orchestrates one or more helper functions
- Enforces naming, validation, and decision rules
- Throws terminating errors on invalid or conflicting state
- Is not silently idempotent unless explicitly documented
- Supports WhatIf / Confirm semantics

This function is intended to be called by:
- Runbooks
- Automation scripts
- CI/CD pipelines

.PARAMETER <RequiredParameter>
Description of the required input parameter.

.PARAMETER <OptionalParameter>
Description of the optional input parameter.

.OUTPUTS
PSCustomObject describing the provisioning result, typically including:
- Resource identifiers
- Status or outcome
- Any created or modified objects

.EXAMPLE
New-MWE<Thing> -<RequiredParameter> 'Value'

Creates and provisions a new <Thing>.

.EXAMPLE
New-MWE<Thing> -<RequiredParameter> 'Value' -WhatIf

Shows what would happen if the provisioning were executed.

.NOTES
- This is a public function and part of the supported module interface.
- Validation and guard clauses are strict by design.
- Helper functions are expected to be deterministic and reusable.
- Logging at this level may use Write-Information for high-level events.

.REQUIRED GRAPH SCOPES
Delegated or Application permissions:
- <Scope.One>
- <Scope.Two>

.LINK
https://learn.microsoft.com/graph/
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RequiredParameter,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OptionalParameter
    )

    # --- Validation / guard clauses ---
    # throw on invalid or conflicting input

    # --- Orchestration ---
    # Call helper functions (New-*, Set-*, Assert-*)

    try {
        if ($PSCmdlet.ShouldProcess("<Target>", "Provision <Thing>")) {
            # Provisioning logic
        }

        Write-Information "<Thing> provisioning completed successfully."
        return [pscustomobject]@{
            Result  = 'Success'
            Target  = $RequiredParameter
        }
    }
    catch {
        throw "Failed to provision <Thing>: $($_.Exception.Message)"
    }
}
