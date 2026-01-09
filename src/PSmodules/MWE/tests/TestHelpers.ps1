Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MWEModuleRoot {
    Split-Path -Path $PSScriptRoot -Parent
}

function Import-MWEModuleUnderTest {
    $moduleRoot = Get-MWEModuleRoot
    $psd1 = Join-Path -Path $moduleRoot -ChildPath 'MWE.psd1'
    if (-not (Test-Path -LiteralPath $psd1)) {
        throw "Test setup failed: module manifest not found: $psd1"
    }

    Remove-Module -Name 'MWE' -Force -ErrorAction SilentlyContinue
    Import-Module -Name $psd1 -Force
}
