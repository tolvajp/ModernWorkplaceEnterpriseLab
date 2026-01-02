#requires -Version 7.2
#requires -Modules Pester
# Pester v5 tests for New-MWEGroup.ps1
# All Microsoft Graph cmdlets are mocked; no network calls.

BeforeAll {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $sut = Join-Path -Path $PSScriptRoot -ChildPath '..\New-MWEGroup.ps1'
    if (-not (Test-Path $sut)) { throw "SUT not found: $sut" }

    . $sut

    if (-not (Get-Command -Name New-MWEGroup -ErrorAction SilentlyContinue)) {
        throw "New-MWEGroup was not loaded from $sut"
    }
}

Describe 'New-MWEGroup' {

    Context 'LICENSE parameter set' {

        BeforeEach {
            Mock -CommandName Get-MgGroup -MockWith { $null }
            Mock -CommandName New-MgGroup -MockWith {
                param($DisplayName,$Description,$MailEnabled,$SecurityEnabled,$MailNickname)
                [pscustomobject]@{ Id = 'g1'; DisplayName = $DisplayName; Description = $Description }
            }
            Mock -CommandName Set-MgGroupLicense -MockWith { }
        }

        It 'throws when SkuPartNumber is not present and -Mock is not used' {
            Mock -CommandName Get-MgSubscribedSku -MockWith {
                @([pscustomobject]@{ SkuPartNumber = 'SPE_E5'; SkuId = [guid]::NewGuid() })
            }

            { New-MWEGroup -SkuPartNumber 'NOT_A_REAL_SKU' -Confirm:$false } | Should -Throw
            Assert-MockCalled -CommandName New-MgGroup -Times 0
            Assert-MockCalled -CommandName Set-MgGroupLicense -Times 0
        }

        It 'creates group and assigns license when SkuPartNumber exists and -Mock is not used' {
            $skuId = [guid]::NewGuid()
            Mock -CommandName Get-MgSubscribedSku -MockWith {
                @([pscustomobject]@{ SkuPartNumber = 'SPE_E5'; SkuId = $skuId })
            }

            $g = New-MWEGroup -SkuPartNumber 'SPE_E5' -Confirm:$false
            $g.DisplayName | Should -Be 'U-LICENSE-SPE_E5'

            Assert-MockCalled -CommandName Get-MgGroup -Times 1
            Assert-MockCalled -CommandName New-MgGroup -Times 1 -Exactly
            Assert-MockCalled -CommandName Set-MgGroupLicense -Times 1 -Exactly
        }

        It 'creates group but does not assign license when -Mock is used' {
            Mock -CommandName Get-MgSubscribedSku -MockWith { @() } # should not be used in -Mock flow

            $g = New-MWEGroup -SkuPartNumber 'SOME_SKU' -Mock -Confirm:$false
            $g.DisplayName | Should -Be 'U-LICENSE-SOME_SKU'

            Assert-MockCalled -CommandName New-MgGroup -Times 1 -Exactly
            Assert-MockCalled -CommandName Set-MgGroupLicense -Times 0
        }

        It 'throws if a group with the same displayName already exists' {
            Mock -CommandName Get-MgSubscribedSku -MockWith {
                @([pscustomobject]@{ SkuPartNumber = 'SPE_E5'; SkuId = [guid]::NewGuid() })
            }
            Mock -CommandName Get-MgGroup -MockWith {
                [pscustomobject]@{ Id='existing'; DisplayName='U-LICENSE-SPE_E5' }
            }

            { New-MWEGroup -SkuPartNumber 'SPE_E5' -Confirm:$false } | Should -Throw
            Assert-MockCalled -CommandName New-MgGroup -Times 0
            Assert-MockCalled -CommandName Set-MgGroupLicense -Times 0
        }
    }

    Context 'ENTRAROLE parameter set' {

        BeforeEach {
            Mock -CommandName Get-MgGroup -MockWith { $null }
            Mock -CommandName New-MgGroup -MockWith {
                param($DisplayName,$Description,$MailEnabled,$SecurityEnabled,$MailNickname)
                [pscustomobject]@{ Id = 'g2'; DisplayName = $DisplayName; Description = $Description }
            }

            Mock -CommandName Get-MgDirectoryRoleTemplate -MockWith {
                @([pscustomobject]@{ DisplayName='Global Administrator'; Id='t1' })
            }

            # Used in validation + activation ensure block
            Mock -CommandName Get-MgDirectoryRole -MockWith {
                @([pscustomobject]@{ DisplayName='Global Administrator'; Id='r1' })
            }
            Mock -CommandName New-MgDirectoryRole -MockWith { }

            Mock -CommandName Get-MgRoleManagementDirectoryRoleDefinition -MockWith {
                @([pscustomobject]@{ Id='rd1'; DisplayName='Global Administrator' })
            }

            Mock -CommandName Get-MgPolicyRoleManagementPolicyAssignment -MockWith {
                @([pscustomobject]@{ PolicyId='p1' })
            }

            Mock -CommandName Get-MgPolicyRoleManagementPolicyRule -MockWith {
                @([pscustomobject]@{ Id='Expiration_EndUser_Assignment' })
            }

            Mock -CommandName Update-MgPolicyRoleManagementPolicyRule -MockWith { }
            Mock -CommandName New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -MockWith { }
            Mock -CommandName New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -MockWith { }
        }

        It 'creates group and submits ACTIVE assignment schedule request' {
            $g = New-MWEGroup -RoleName 'Global Administrator' -AssignmentType 'Active' -MaximumActivationHours 5 -Confirm:$false
            $g.DisplayName | Should -Be 'U-ENTRAROLE-GlobalAdministrator-ACTIVE'

            Assert-MockCalled -CommandName New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -Times 1 -Exactly
            Assert-MockCalled -CommandName New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -Times 0 -Exactly
            Assert-MockCalled -CommandName Update-MgPolicyRoleManagementPolicyRule -Times 1 -Exactly
        }

        It 'creates group and submits ELIGIBLE schedule request' {
            $g = New-MWEGroup -RoleName 'Global Administrator' -AssignmentType 'Eligible' -MaximumActivationHours 5 -Confirm:$false
            $g.DisplayName | Should -Be 'U-ENTRAROLE-GlobalAdministrator-ELIGIBLE'

            Assert-MockCalled -CommandName New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -Times 1 -Exactly
            Assert-MockCalled -CommandName New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -Times 0 -Exactly
            Assert-MockCalled -CommandName Update-MgPolicyRoleManagementPolicyRule -Times 1 -Exactly
        }

        It 'throws when role definition cannot be found' {
            Mock -CommandName Get-MgRoleManagementDirectoryRoleDefinition -MockWith { @() }

            { New-MWEGroup -RoleName 'Global Administrator' -AssignmentType 'Eligible' -Confirm:$false } | Should -Throw
        }

        It 'throws when policy assignment is missing' {
            Mock -CommandName Get-MgPolicyRoleManagementPolicyAssignment -MockWith { @() }

            { New-MWEGroup -RoleName 'Global Administrator' -AssignmentType 'Eligible' -Confirm:$false } | Should -Throw
        }

        It 'throws when expiration rule is missing' {
            Mock -CommandName Get-MgPolicyRoleManagementPolicyRule -MockWith { @() }

            { New-MWEGroup -RoleName 'Global Administrator' -AssignmentType 'Eligible' -Confirm:$false } | Should -Throw
        }
    }
}
