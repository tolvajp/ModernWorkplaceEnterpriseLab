#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

#assigning the right json config file based on the runbook name
$runbookNumber = ($MyInvocation.MyCommand.Name -split '[-.]')[1]
$configPath    = Join-Path -Path $PSScriptRoot -ChildPath "RNB-$runbookNumber.json"

if (Test-Path -LiteralPath $configPath) {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json -AsHashtable
    #Checking if msgraph connection exists and has required scopes
    if ($config -and $config.Auth.Scopes) {
        #checking if all the needed scopess are present in the existing connection
        if (Get-MgContext) {
            $expected=@($config.Auth.Scopes)
            $factual=@((Get-MgContext).Scopes | Where-Object { $_ -match '\.' })
            $missing = (Compare-Object -ReferenceObject $expected -DifferenceObject $factual | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject })
            if ($missing) {
                Disconnect-MgGraph
                Connect-MgGraph -Scopes ($factual + $missing) 
            }
        } else {
            Connect-MgGraph -Scopes $config.Auth.Scopes
        }
    }
    Write-Host "Config found and loaded: $configPath"
}else {
    Write-Host "Config file not found: $configPath"
}
