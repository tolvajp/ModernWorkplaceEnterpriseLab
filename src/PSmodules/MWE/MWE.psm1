#Requires -Version 7.2
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Load private helpers at import time so internal functions are available immediately.
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File | ForEach-Object {
    . $_.FullName
}

. (Join-Path $PSScriptRoot 'New-MWEGroup.ps1')

Export-ModuleMember -Function 'New-MWEGroup'
