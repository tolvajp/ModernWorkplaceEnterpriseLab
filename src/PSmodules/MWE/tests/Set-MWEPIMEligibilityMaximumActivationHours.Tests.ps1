# Set-MWEPIMEligibilityMaximumActivationHours.Tests.ps1
# Pester v5.7.x
#
# Safety goals:
# - Ensure the function under test is loaded even if it is not exported.
# - Ensure NO real Graph/tenant calls can occur: we "default deny" by mocking
#   Invoke-MgGraphRequest so any accidental passthrough fails fast.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')

    # Import module under test (exports etc.)
    Import-MWEModuleUnderTest

    # Load all helper scripts (Private + Public) AND the function under test by dot-sourcing.
    # This makes internal helper commands available for Mocking and ensures the function exists.
    $moduleRoot = Get-MWEModuleRoot

    foreach ($sub in @('Private','Public')) {
        $p = Join-Path -Path $moduleRoot -ChildPath $sub
        if (Test-Path -LiteralPath $p) {
            Get-ChildItem -LiteralPath $p -Filter '*.ps1' -File | ForEach-Object { . $_.FullName }
        }
    }

    # Dot-source the function under test if it wasn't brought in via Public folder.
    if (-not (Get-Command -Name 'Set-MWEPIMEligibilityMaximumActivationHours' -ErrorAction SilentlyContinue)) {
        $fn = Get-ChildItem -LiteralPath $moduleRoot -Recurse -Filter 'Set-MWEPIMEligibilityMaximumActivationHours.ps1' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $fn) { throw "Test setup failed: could not locate Set-MWEPIMEligibilityMaximumActivationHours.ps1 under $moduleRoot" }
        . $fn.FullName
    }

    # Ensure wrapper commands exist so Pester can Mock them in any module layout.
    if (-not (Get-Command -Name 'Invoke-NWEWithLazyObject' -ErrorAction SilentlyContinue)) {
        function Invoke-NWEWithLazyObject {
            param([Parameter(Mandatory)][scriptblock]$ScriptBlock,[string[]]$ErrorIdPatterns,[string[]]$ErrorMessagePatterns,[int]$TimeoutSeconds,[int]$SleepSeconds)
            throw "Invoke-NWEWithLazyObject stub executed (should be mocked)."
        }
    }
    if (-not (Get-Command -Name 'Invoke-MWECommand' -ErrorAction SilentlyContinue)) {
        function Invoke-MWECommand {
            param([Parameter(Mandatory)][hashtable]$Splat)
            throw "Invoke-MWECommand stub executed (should be mocked)."
        }
    }

    # Default-deny Graph call surface: ensure a command exists that we can Mock.
    if (-not (Get-Command -Name 'Invoke-MgGraphRequest' -ErrorAction SilentlyContinue)) {
        function Invoke-MgGraphRequest {
            param()
            throw "Invoke-MgGraphRequest stub executed (should be mocked)."
        }
    }

    $script:roleDefinitionId = '62e90394-69f5-4237-9190-012177145e10'
}

Describe 'Set-MWEPIMEligibilityMaximumActivationHours' {

    BeforeEach {
        # Hard safety net: if anything tries to call Graph directly, fail the test immediately.
        Mock -CommandName Invoke-MgGraphRequest -MockWith { throw 'SAFETY: Invoke-MgGraphRequest was called unexpectedly.' }
    }

    Context 'Must-have: parameter contract' {

        It 'Throws when MaximumActivationHours is below 1' {
            { Set-MWEPIMEligibilityMaximumActivationHours -RoleDefinitionId $script:roleDefinitionId -MaximumActivationHours 0 } | Should -Throw
        }

        It 'Throws when MaximumActivationHours is above 9' {
            { Set-MWEPIMEligibilityMaximumActivationHours -RoleDefinitionId $script:roleDefinitionId -MaximumActivationHours 10 } | Should -Throw
        }

        It 'Throws when RoleDefinitionId is empty' {
            { Set-MWEPIMEligibilityMaximumActivationHours -RoleDefinitionId '' -MaximumActivationHours 1 } | Should -Throw
        }
    }

    Context 'Must-have: happy path + payload correctness' {

        BeforeEach {
            $script:LastPatch = $null

            Mock -CommandName Invoke-NWEWithLazyObject -MockWith {
                [pscustomobject]@{ value = @([pscustomobject]@{ policyId = 'POL-1' }) }
            }

            Mock -CommandName Invoke-MWECommand -ParameterFilter { $Splat.Method -eq 'GET' } -MockWith {
                [pscustomobject]@{
                    value = @(
                        [pscustomobject]@{
                            '@odata.type' = '#microsoft.graph.unifiedRoleManagementPolicyExpirationRule'
                            id     = 'RULE-1'
                            target = [pscustomobject]@{ caller = 'EndUser'; level = 'Eligible' }
                        }
                    )
                }
            }

            Mock -CommandName Invoke-MWECommand -ParameterFilter { $Splat.Method -eq 'PATCH' } -MockWith {
                $script:LastPatch = $Splat
                $null
            }

            Mock -CommandName Write-Information -MockWith { }
        }

        It 'PATCHes ISO duration PT{n}H and requires expiration' {
            $result = Set-MWEPIMEligibilityMaximumActivationHours -RoleDefinitionId $script:roleDefinitionId -MaximumActivationHours 3 -Confirm:$false

            $result | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-MWECommand -Times 1 -Exactly -ParameterFilter { $Splat.Method -eq 'PATCH' }

            $script:LastPatch | Should -Not -BeNullOrEmpty
            $script:LastPatch.Body.maximumDuration | Should -Be 'PT3H'
            $script:LastPatch.Body.isExpirationRequired | Should -BeTrue
        }
    }

    Context 'Must-have: WhatIf gate' {

        BeforeEach {
            # Under -WhatIf the function still performs the GET calls (policy assignment + rules),
            # but must NOT perform the PATCH nor write information.
            Mock -CommandName Invoke-NWEWithLazyObject -MockWith {
                [pscustomobject]@{ value = @([pscustomobject]@{ policyId = 'POL-1' }) }
            }

            # Return a valid rules response so the function can proceed up to the ShouldProcess gate.
            Mock -CommandName Invoke-MWECommand -ParameterFilter { $Splat.Method -eq 'GET' } -MockWith {
                [pscustomobject]@{
                    value = @(
                        [pscustomobject]@{
                            '@odata.type' = '#microsoft.graph.unifiedRoleManagementPolicyExpirationRule'
                            id     = 'RULE-1'
                            target = [pscustomobject]@{ caller = 'EndUser'; level = 'Eligible' }
                        }
                    )
                }
            }

            # If PATCH is called under -WhatIf, fail fast.
            Mock -CommandName Invoke-MWECommand -ParameterFilter { $Splat.Method -eq 'PATCH' } -MockWith {
                throw 'PATCH should not be called under -WhatIf'
            }

            Mock -CommandName Write-Information -MockWith { throw 'Write-Information should not be called under -WhatIf' }
        }

        It 'Does not PATCH under -WhatIf' {
            { Set-MWEPIMEligibilityMaximumActivationHours -RoleDefinitionId $script:roleDefinitionId -MaximumActivationHours 2 -WhatIf } | Should -Not -Throw

            Assert-MockCalled -CommandName Invoke-NWEWithLazyObject -Times 1 -Exactly
            Assert-MockCalled -CommandName Invoke-MWECommand -Times 1 -Exactly -ParameterFilter { $Splat.Method -eq 'GET' }
            Assert-MockCalled -CommandName Invoke-MWECommand -Times 0 -Exactly -ParameterFilter { $Splat.Method -eq 'PATCH' }
            Assert-MockCalled -CommandName Write-Information -Times 0 -Exactly
        }
    }

    Context 'Strongly recommended: rule selection priority' {

        BeforeEach {
            $script:LastPatch = $null

            Mock -CommandName Invoke-NWEWithLazyObject -MockWith {
                [pscustomobject]@{ value = @([pscustomobject]@{ policyId = 'POL-1' }) }
            }

            Mock -CommandName Invoke-MWECommand -ParameterFilter { $Splat.Method -eq 'PATCH' } -MockWith {
                $script:LastPatch = $Splat
                $null
            }

            Mock -CommandName Write-Information -MockWith { }
        }

        It 'Prefers Eligible + EndUser rule' {
            Mock -CommandName Invoke-MWECommand -ParameterFilter { $Splat.Method -eq 'GET' } -MockWith {
                [pscustomobject]@{
                    value = @(
                        [pscustomobject]@{
                            '@odata.type' = '#microsoft.graph.unifiedRoleManagementPolicyExpirationRule'
                            id     = 'RULE-LOW'
                            target = [pscustomobject]@{ caller = 'EndUser'; level = 'Member' }
                        },
                        [pscustomobject]@{
                            '@odata.type' = '#microsoft.graph.unifiedRoleManagementPolicyExpirationRule'
                            id     = 'RULE-HIGH'
                            target = [pscustomobject]@{ caller = 'EndUser'; level = 'Eligible' }
                        }
                    )
                }
            }

            Set-MWEPIMEligibilityMaximumActivationHours -RoleDefinitionId $script:roleDefinitionId -MaximumActivationHours 1 -Confirm:$false | Out-Null
            $script:LastPatch.Uri | Should -Match 'RULE-HIGH$'
        }
    }
}
