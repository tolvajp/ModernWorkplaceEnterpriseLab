#Requires -Version 7.2
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. $PSScriptRoot\New-MWEGroup.ps1
Export-ModuleMember -Function 'New-MWEGroup'