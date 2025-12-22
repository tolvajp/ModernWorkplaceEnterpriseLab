#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest


$runbookNumber = ($MyInvocation.MyCommand.Name -split '[-.]')[1]
$configPath    = Join-Path -Path $PSScriptRoot -ChildPath "RNB-$runbookNumber.json"

if (Test-Path -LiteralPath $configPath) {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json -AsHashtable
    Write-Host "Config found and loaded: $configPath"
}
else {
    Write-Host "Config file not found: $configPath"
}
