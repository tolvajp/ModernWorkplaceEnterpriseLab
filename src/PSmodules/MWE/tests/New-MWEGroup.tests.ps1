#Requires -Version 7.2
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- LOAD MODULE DURING DISCOVERY ---
Get-Module MWE -All | Remove-Module -Force

$here = Split-Path -Parent $PSCommandPath
$moduleRoot = Split-Path -Parent $here
$manifestPath = Join-Path $moduleRoot 'MWE.psd1'

Import-Module $manifestPath -Force
# --- END LOAD ---


InModuleScope MWE {

    Describe 'New-MWEGroup' {

        BeforeEach {
            # Default mocks (prevent real Graph calls)
            Mock Get-MgGroup { $null }

            $skuId = [guid]'11111111-1111-1111-1111-111111111111'
            Mock Get-MgSubscribedSku {
                @(
                    [pscustomobject]@{
                        SkuPartNumber = 'SPE_E5'
                        SkuId         = $skuId
                    }
                )
            }

            Mock New-MgGroup {
                param(
                    [string]$DisplayName,
                    [string]$Description,
                    [bool]$MailEnabled,
                    [bool]$SecurityEnabled,
                    [string]$MailNickname
                )

                [pscustomobject]@{
                    Id          = 'grp-777'
                    DisplayName = $DisplayName
                    Description = $Description
                    MailEnabled = $MailEnabled
                    SecurityEnabled = $SecurityEnabled
                    MailNickname = $MailNickname
                }
            }

            Mock Set-MgGroupLicense { }
        }

        Context 'Parameter and SKU validation' {

            It 'Throws when -Mock is not specified and SkuPartNumber is not present in Get-MgSubscribedSku' {
                Mock Get-MgSubscribedSku { @([pscustomobject]@{ SkuPartNumber = 'SOME_OTHER_SKU'; SkuId = [guid]::NewGuid() }) }

                { New-MWEGroup -SkuPartNumber 'SPE_E5' } | Should -Throw -ExpectedMessage 'No such License bought for the company: SPE_E5'
                Assert-MockCalled Get-MgGroup -Times 0
                Assert-MockCalled New-MgGroup -Times 0
                Assert-MockCalled Set-MgGroupLicense -Times 0
            }

            It 'Does not throw in -Mock mode even if SKU does not exist' {
                Mock Get-MgSubscribedSku { @() }

                { New-MWEGroup -SkuPartNumber 'SPE_E5' -Mock } | Should -Not -Throw
                Assert-MockCalled New-MgGroup -Times 1
                Assert-MockCalled Set-MgGroupLicense -Times 0
            }
        }

        Context 'Group creation behavior' {

            It 'Throws when group already exists' {
                Mock Get-MgGroup { [pscustomobject]@{ Id = 'existing-1' } }

                { New-MWEGroup -SkuPartNumber 'SPE_E5' -Mock } | Should -Throw -ExpectedMessage "Group 'U-LICENSE-SPE_E5' already exists*"
                Assert-MockCalled New-MgGroup -Times 0
                Assert-MockCalled Set-MgGroupLicense -Times 0
            }

            It 'Creates group with deterministic normalized name and properties' {
                $result = New-MWEGroup -SkuPartNumber 'SPE_E5' -Mock

                $result | Should -Not -BeNullOrEmpty
                $result.DisplayName | Should -Be 'U-LICENSE-SPE_E5'
                $result.MailEnabled | Should -BeFalse
                $result.SecurityEnabled | Should -BeTrue
                $result.MailNickname | Should -Be 'U-LICENSE-SPE_E5'
                $result.Description | Should -Be 'License assignment group for SPE_E5'

                Assert-MockCalled New-MgGroup -Times 1
                Assert-MockCalled Set-MgGroupLicense -Times 0
            }

            It 'Does not create anything and returns $null when -WhatIf is used' {
                $result = New-MWEGroup -SkuPartNumber 'SPE_E5' -Mock -WhatIf

                $result | Should -BeNullOrEmpty
                Assert-MockCalled New-MgGroup -Times 0
                Assert-MockCalled Set-MgGroupLicense -Times 0
            }
        }

        Context 'License assignment behavior' {

            It 'Assigns license to the newly created group when not -Mock' {
                $expectedSkuId = [guid]'11111111-1111-1111-1111-111111111111'

                Mock Set-MgGroupLicense {
                    param($AddLicenses, $RemoveLicenses, $GroupId)

                    $GroupId | Should -Be 'grp-777'
                    $RemoveLicenses.Count | Should -Be 0
                    $AddLicenses.Count | Should -Be 1
                    $AddLicenses[0].SkuId | Should -Be $expectedSkuId
                }

                $null = New-MWEGroup -SkuPartNumber 'SPE_E5'
                Assert-MockCalled Set-MgGroupLicense -Times 1 -Exactly
            }

            It 'Skips license assignment in -Mock mode' {
                $null = New-MWEGroup -SkuPartNumber 'SPE_E5' -Mock
                Assert-MockCalled Set-MgGroupLicense -Times 0
            }
        }

        Context 'Naming constraints' {

            It 'Throws when normalized group name exceeds 64 characters' {
                $longSku = 'X' * 70

                { New-MWEGroup -SkuPartNumber $longSku -Mock } | Should -Throw -ExpectedMessage "Normalized group name '*is longer than 64 characters*"
                Assert-MockCalled New-MgGroup -Times 0
            }

            It 'Normalizes display name by stripping invalid characters' {
                $result = New-MWEGroup -SkuPartNumber 'SPE E5!!' -Mock

                $result.DisplayName | Should -Be 'U-LICENSE-SPEE5'
                Assert-MockCalled New-MgGroup -Times 1
            }
        }
    }
}
