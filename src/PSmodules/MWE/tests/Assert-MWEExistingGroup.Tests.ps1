BeforeAll {
    . "$PSScriptRoot\TestHelpers.ps1"
    Import-MWEModuleUnderTest

    # Assert-MWEExistingGroup is a private helper; dot-source it for testing.
    $moduleRoot = Get-MWEModuleRoot
    $candidatePaths = @(
        (Join-Path -Path $moduleRoot -ChildPath 'Private\Assert-MWEExistingGroup.ps1'),
        (Join-Path -Path $moduleRoot -ChildPath 'Assert-MWEExistingGroup.ps1')
    )

    $helperPath = $candidatePaths | Where-Object { Test-Path -Path $_ } | Select-Object -First 1
    if (-not $helperPath) { throw "Assert-MWEExistingGroup.ps1 not found under module root: $moduleRoot" }

    # Ensure commands exist for Pester Mock, even if not exported into global scope.
    if (-not (Get-Command -Name 'Invoke-MWECommand' -ErrorAction SilentlyContinue)) {
        function Invoke-MWECommand { param([string]$Command,[hashtable]$Splat) }
    }
    if (-not (Get-Command -Name 'Get-MgGroup' -ErrorAction SilentlyContinue)) {
        function Get-MgGroup { param([string]$Filter,[int]$Top) }
    }

    . $helperPath
}

Describe 'Assert-MWEExistingGroup' {

    BeforeEach {
        # Default: name builder returns deterministic names
        Mock -CommandName Invoke-MWECommand -MockWith {
            param([string]$Command,[hashtable]$Splat)

            switch ($Command) {
                'Get-MWEGroupDisplayName' {
                    if ($Splat.Intent -eq 'LICENSE') { return "U-LICENSE-$($Splat.SkuPartNumber)" }
                    if ($Splat.Intent -eq 'ENTRAROLE') { return "U-ENTRAROLE-$($Splat.RoleName -replace ' ','')-$($Splat.AssignmentType.ToUpperInvariant())" }
                    return 'UNKNOWN'
                }
                'Get-MgGroup' {
                    return $null
                }
                default {
                    throw "Unexpected Invoke-MWECommand call: $Command"
                }
            }
        }

        Mock -CommandName Get-MgGroup -MockWith { return $null }
    }

    Context 'Parameter contract' {

        It "Throws when SkuPartNumber is missing for LICENSE" {
            $ex = { Assert-MWEExistingGroup -Intent LICENSE } | Should -Throw -PassThru
            $ex.Exception.Message | Should -Match "SkuPartNumber is required when Intent is 'LICENSE'"
        }

        It "Throws when RoleName is missing for ENTRAROLE" {
            $ex = { Assert-MWEExistingGroup -Intent ENTRAROLE } | Should -Throw -PassThru
            $ex.Exception.Message | Should -Match "RoleName is required when Intent is 'ENTRAROLE'"
        }

        It 'Rejects invalid Intent values (ValidateSet)' {
            { Assert-MWEExistingGroup -Intent 'NOPE' -SkuPartNumber 'X' } | Should -Throw
        }
    }

    Context 'LICENSE intent' {

        It 'Does not throw when no existing group is found' {
            { Assert-MWEExistingGroup -Intent LICENSE -SkuPartNumber 'SPE_E5' } | Should -Not -Throw
        }

        It 'Throws when an existing group is found' {
            Mock -CommandName Get-MgGroup -MockWith {
                [pscustomobject]@{ DisplayName = 'U-LICENSE-SPE_E5'; Id = '1111' }
            }

            $ex = { Assert-MWEExistingGroup -Intent LICENSE -SkuPartNumber 'SPE_E5' } | Should -Throw -PassThru
            $ex.Exception.Message | Should -Match "Group 'U-LICENSE-SPE_E5' already exists with Id: 1111\. Use that one\."
        }

        It 'Calls Get-MgGroup with exact OData filter (displayName eq) and Top 1' {
            { Assert-MWEExistingGroup -Intent LICENSE -SkuPartNumber 'SPE_E5' } | Should -Not -Throw

            Assert-MockCalled -CommandName Get-MgGroup -Times 1 -Exactly -Scope It -ParameterFilter {
                $Top -eq 1 -and $Filter -eq "displayName eq 'U-LICENSE-SPE_E5'"
            }
        }

        It 'Calls Get-MWEGroupDisplayName exactly once for LICENSE' {
            { Assert-MWEExistingGroup -Intent LICENSE -SkuPartNumber 'SPE_E5' } | Should -Not -Throw

            Assert-MockCalled -CommandName Invoke-MWECommand -Times 1 -Exactly -Scope It -ParameterFilter {
                $Command -eq 'Get-MWEGroupDisplayName' -and $Splat.Intent -eq 'LICENSE' -and $Splat.SkuPartNumber -eq 'SPE_E5'
            }
        }

        It 'Returns no output on success' {
            $result = Assert-MWEExistingGroup -Intent LICENSE -SkuPartNumber 'SPE_E5'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'ENTRAROLE intent' {

        It 'Does not throw when neither Eligible nor Active group exists' {
            { Assert-MWEExistingGroup -Intent ENTRAROLE -RoleName 'Global Administrator' } | Should -Not -Throw
        }

        It 'Throws when Eligible group exists (Active does not)' {
            Mock -CommandName Invoke-MWECommand -MockWith {
                param([string]$Command,[hashtable]$Splat)

                if ($Command -eq 'Get-MWEGroupDisplayName') {
                    return "U-ENTRAROLE-$($Splat.RoleName -replace ' ','')-$($Splat.AssignmentType.ToUpperInvariant())"
                }

                if ($Command -eq 'Get-MgGroup') {
                    # Simulate Eligible existing
                    [pscustomobject]@{ DisplayName = 'U-ENTRAROLE-GlobalAdministrator-ELIGIBLE'; Id = 'E1' }
                }
            }

            $ex = { Assert-MWEExistingGroup -Intent ENTRAROLE -RoleName 'Global Administrator' } | Should -Throw -PassThru
            $ex.Exception.Message | Should -Match "Group 'U-ENTRAROLE-GlobalAdministrator-ELIGIBLE' already exists with Id: E1\. Use that one\."
        }

        It 'Throws when Active group exists (Eligible does not)' {
            Mock -CommandName Invoke-MWECommand -MockWith {
                param([string]$Command,[hashtable]$Splat)

                if ($Command -eq 'Get-MWEGroupDisplayName') {
                    return "U-ENTRAROLE-$($Splat.RoleName -replace ' ','')-$($Splat.AssignmentType.ToUpperInvariant())"
                }

                if ($Command -eq 'Get-MgGroup') {
                    # Simulate Active existing
                    [pscustomobject]@{ DisplayName = 'U-ENTRAROLE-GlobalAdministrator-ACTIVE'; Id = 'A1' }
                }
            }

            $ex = { Assert-MWEExistingGroup -Intent ENTRAROLE -RoleName 'Global Administrator' } | Should -Throw -PassThru
            $ex.Exception.Message | Should -Match "Group 'U-ENTRAROLE-GlobalAdministrator-ACTIVE' already exists with Id: A1\. Use that one\."
        }

        It 'Throws when either (Eligible/Active) exists (Top 1 means any match is enough)' {
            Mock -CommandName Invoke-MWECommand -MockWith {
                param([string]$Command,[hashtable]$Splat)

                if ($Command -eq 'Get-MWEGroupDisplayName') {
                    return "U-ENTRAROLE-$($Splat.RoleName -replace ' ','')-$($Splat.AssignmentType.ToUpperInvariant())"
                }

                if ($Command -eq 'Get-MgGroup') {
                    # Simulate at least one existing group (Eligible)
                    [pscustomobject]@{ DisplayName = 'U-ENTRAROLE-GlobalAdministrator-ELIGIBLE'; Id = 'X1' }
                }
            }

            { Assert-MWEExistingGroup -Intent ENTRAROLE -RoleName 'Global Administrator' } | Should -Throw
        }

        It 'Calls Get-MWEGroupDisplayName exactly twice for ENTRAROLE (Eligible + Active)' {
            { Assert-MWEExistingGroup -Intent ENTRAROLE -RoleName 'Global Administrator' } | Should -Not -Throw

            Assert-MockCalled -CommandName Invoke-MWECommand -Times 1 -Exactly -Scope It -ParameterFilter {
                $Command -eq 'Get-MWEGroupDisplayName' -and $Splat.Intent -eq 'ENTRAROLE' -and $Splat.RoleName -eq 'Global Administrator' -and $Splat.AssignmentType -eq 'Eligible'
            }
            Assert-MockCalled -CommandName Invoke-MWECommand -Times 1 -Exactly -Scope It -ParameterFilter {
                $Command -eq 'Get-MWEGroupDisplayName' -and $Splat.Intent -eq 'ENTRAROLE' -and $Splat.RoleName -eq 'Global Administrator' -and $Splat.AssignmentType -eq 'Active'
            }
        }

        It 'Uses Invoke-MWECommand to query groups (Get-MgGroup) for ENTRAROLE' {
            { Assert-MWEExistingGroup -Intent ENTRAROLE -RoleName 'Global Administrator' } | Should -Not -Throw

            Assert-MockCalled -CommandName Invoke-MWECommand -Times 1 -Exactly -Scope It -ParameterFilter {
                $Command -eq 'Get-MgGroup' -and $Splat.Top -eq 1 -and $Splat.Filter -match 'displayName eq'
            }
        }

        It 'Does not call direct Get-MgGroup for ENTRAROLE (only via Invoke-MWECommand)' {
            { Assert-MWEExistingGroup -Intent ENTRAROLE -RoleName 'Global Administrator' } | Should -Not -Throw

            Assert-MockCalled -CommandName Get-MgGroup -Times 0 -Exactly -Scope It
        }

        It 'Returns no output on success' {
            $result = Assert-MWEExistingGroup -Intent ENTRAROLE -RoleName 'Global Administrator'
            $result | Should -BeNullOrEmpty
        }
    }
}
