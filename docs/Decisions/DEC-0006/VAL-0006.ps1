#Requires -Version 7.2
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ConfigPath='C:\git\ModernWorkplaceEnterpriseLab\docs\Decisions\DEC-0006\VAL-0006.json'


function ConvertTo-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject
    )

    if ($InputObject -is [hashtable]) { return $InputObject }

    $ht = @{}
    foreach ($p in $InputObject.PSObject.Properties) {
        $ht[$p.Name] = $p.Value
    }
    return $ht
}

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$results = @()

foreach ($test in $config.EntraRoles) {
    Write-Host "Running test [$($test.TestId)]..."

    $passed = $false
    $err = $null

    try {
        $splat = ConvertTo-Hashtable -InputObject $test.GroupSplat
        $null = New-MWEGroup @splat
        if ($test.ExpectedToFail) {
            $passed = $false
            $err = "Expected failure but command succeeded."
        } else {
            $passed = $true
        }
    } catch {
        $err = $_.Exception.Message
        if ($test.ExpectedToFail) {
            if ($test.PSObject.Properties.Name -contains 'ExpectedErrorRegex' -and $test.ExpectedErrorRegex) {
                $passed = ($err -match $test.ExpectedErrorRegex)
                if (-not $passed) {
                    $err = "Error message mismatch. Actual: $err"
                }
            } else {
                $passed = $true
            }
        } else {
            $passed = $false
        }
    }

    if ($passed) {
        Write-Host "✅ Test passed [$($test.TestId)]"
    } else {
        Write-Warning "❌ Test failed [$($test.TestId)]"
    }

    $results += [pscustomobject]@{
        TestId         = $test.TestId
        Passed         = $passed
        ExpectedToFail = [bool]$test.ExpectedToFail
        Error          = $err
    }
}

"`n=== TEST SUMMARY ===`n"
$results | Format-Table -AutoSize

if ($results.Where({ -not $_.Passed }).Count -gt 0) {
    throw "One or more tests failed."
}
