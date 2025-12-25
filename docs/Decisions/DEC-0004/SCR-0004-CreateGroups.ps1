#Requires -Version 7.2
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param (
    [Parameter(Mandatory)]
    [string]$ConfigPath
)

if (-not (Test-Path $ConfigPath)) {
    throw "Config file not found: $ConfigPath"
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

Connect-MgGraph -Scopes Group.ReadWrite.All

function Ensure-Group {
    param (
        [string]$Name,
        [string]$Description
    )

    $existing = Get-MgGroup -Filter "displayName eq '$Name'" -ErrorAction SilentlyContinue
    if (-not $existing) {
        New-MgGroup -DisplayName $Name -Description $Description -MailEnabled:$false -SecurityEnabled:$true -MailNickname $Name
    }
}

foreach ($g in $config.LicenseGroups) { Ensure-Group $g.Name $g.Description }
foreach ($g in $config.RoleGroups) { Ensure-Group $g.Name $g.Description }
foreach ($g in $config.DepartmentGroups) { Ensure-Group $g.Name $g.Description }
