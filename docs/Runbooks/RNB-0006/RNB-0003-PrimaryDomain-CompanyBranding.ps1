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

# --- Known input ---
$domainName = $config.CustomDomain.DomainName
$branding   = $config.CompanyBranding

# --- Set primary domain ---
Update-MgDomain -DomainId $domainName -IsDefault:$true

# --- Prepare files ---
$bannerPath = Join-Path -Path $PSScriptRoot -ChildPath $branding.BannerLogoPath
$squarePath = Join-Path -Path $PSScriptRoot -ChildPath $branding.SquareLogoPath
$bgPath     = Join-Path -Path $PSScriptRoot -ChildPath $branding.SignInBackgroundImagePath

$bannerBytes = [System.IO.File]::ReadAllBytes($bannerPath)
$squareBytes = [System.IO.File]::ReadAllBytes($squarePath)
$bgBytes     = [System.IO.File]::ReadAllBytes($bgPath)

$orgId = (Get-MgOrganization).Id

# --- Update branding text (non-stream properties) ---
Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/organization/$orgId/branding" -Body @{
    signInPageText = $branding.SignInPageText
} | Out-Null

# --- Upload stream properties (images) ---
Invoke-MgGraphRequest -Method PUT -Uri "/v1.0/organization/$orgId/branding/localizations/0/bannerLogo"      -Body $bannerBytes -ContentType "image/png" | Out-Null
Invoke-MgGraphRequest -Method PUT -Uri "/v1.0/organization/$orgId/branding/localizations/0/backgroundImage" -Body $bgBytes     -ContentType "image/png" | Out-Null
Invoke-MgGraphRequest -Method PUT -Uri "/v1.0/organization/$orgId/branding/localizations/0/squareLogo"      -Body $squareBytes -ContentType "image/png" | Out-Null

Write-Host "Primary domain set and company branding updated (text + images)."