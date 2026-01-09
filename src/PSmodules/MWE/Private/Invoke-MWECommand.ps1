function Invoke-MWECommand {
    <#
.SYNOPSIS
Invokes a PowerShell command with a splatted parameter set and standardized verbose logging.

.DESCRIPTION
Invokes an existing PowerShell command (function, cmdlet, alias, or script)
using the call operator (`&`) and a hashtable splat.

This helper exists to provide a single, consistent place for:
- verbose logging of invoked commands
- verbose logging of splatted parameters
- transparent forwarding of output and common parameters (WhatIf / Confirm)

This function:
- Is intended for internal module use
- Does not perform orchestration logic
- Does not perform state changes on its own
- Does not implement idempotency
- Does not gate execution via ShouldProcess
- Preserves the invoked command's output and pipeline behavior
- Does not use Invoke-Expression or AST manipulation

.PARAMETER Command
The name of the PowerShell command to invoke.
This may be a function, cmdlet, alias, or script that is resolvable at invocation time.

.PARAMETER Splat
A hashtable containing the parameters to splat into the invoked command.
Switch parameters must be represented by key presence (for example: Force = $true).

.OUTPUTS
Whatever objects are emitted by the invoked command.
This function does not wrap, modify, or replace the output.
This function only adds to verbose log stream for debugging purposes.

.EXAMPLE
Invoke-MWECommand -Command 'Get-ChildItem' -Splat @{
    Path    = '.'
    Recurse = $true
}

.EXAMPLE
Invoke-MWECommand -Command 'Set-MWEGroupEntraRoleAssignment' -Splat @{
    GroupId        = $GroupId
    RoleName       = 'Global Administrator'
    AssignmentType = 'Eligible'
    Force          = $true
}

.EXAMPLE
Invoke-MWECommand -Command 'New-MWEGroup' -Splat $splat -Verbose -WhatIf

.NOTES
- Internal helper function
- Designed for reuse by higher-level MWE functions
- Intended as a transparent command forwarder with enhanced observability
- Throws terminating errors emitted by the invoked command without interception
- SupportsShouldProcess is present only to preserve WhatIf/Confirm parameter binding for forwarded commands.

.REQUIRED GRAPH SCOPES
Depends entirely on the invoked command.
This helper itself does not require Microsoft Graph permissions.

.LINK
https://learn.microsoft.com/powershell/
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param (

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]$Splat
    )
    $ErrorActionPreference = 'Stop'
    Write-Verbose -Message "Invoking command [$Command]"
    if ($Splat.Count -eq 0) {
        Write-Verbose -Message "  - No parameters supplied (empty splat)."
    } else {
        Write-Verbose -Message "  - Parameters:"
        foreach ($key in ($Splat.Keys | Sort-Object)) {
            Write-Verbose "    - $key = $($Splat[$key])"
        }
    }

    # --- Invocation ---
    & $Command @Splat
}
