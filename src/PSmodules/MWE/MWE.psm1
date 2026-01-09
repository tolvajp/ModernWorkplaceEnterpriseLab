#Requires -Version 7.2
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Verbose "MWE.psm1 executing from: $PSCommandPath"
Write-Verbose "ModuleBase: $($ExecutionContext.SessionState.Module.ModuleBase)"

$moduleRoot = $ExecutionContext.SessionState.Module.ModuleBase


function Get-MWEScriptFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter()]
        [switch]$Recurse
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Get-MWEScriptFiles: Path not found: $Path"
    }

    Get-ChildItem -Path $Path -Filter '*.ps1' -File -Recurse:$Recurse |
        Sort-Object -Property FullName
}


$moduleRoot = $ExecutionContext.SessionState.Module.ModuleBase

# Private
$privatePath = Join-Path -Path $moduleRoot -ChildPath 'Private'
Write-Verbose "Loading private scripts from: $privatePath"
foreach ($file in (Get-MWEScriptFiles -Path $privatePath -Recurse)) {
    Write-Verbose "Dot-sourcing: $($file.FullName)"
    . $file.FullName
}

# Public
Write-Verbose "Loading public scripts from: $moduleRoot"
foreach ($file in (Get-MWEScriptFiles -Path $moduleRoot)) {
    if ($file.Name -notin @('MWE.psm1')) {
        Write-Verbose "Dot-sourcing: $($file.FullName)"
        . $file.FullName
    }
}

Export-ModuleMember -Function 'New-MWEGroup'