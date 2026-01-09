# New-MWEGroup.Tests.ps1
# Pester v5.7.x
#
# Scope:
# - Wrappers are tested elsewhere.
# - Each helper is tested elsewhere.
# - Here we test ONLY New-MWEGroup orchestration: parameter contract, flow, helper call wiring, ShouldProcess gate.
#
# Safety:
# - Default-deny any accidental direct Graph calls.
# - Default-deny any unexpected Invoke-MWECommand -Command values (fail fast).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
    Import-MWEModuleUnderTest

    # Ensure the function under test is available even if not exported
    $moduleRoot = Get-MWEModuleRoot
    foreach ($sub in @('Private','Public')) {
        $p = Join-Path -Path $moduleRoot -ChildPath $sub
        if (Test-Path -LiteralPath $p) {
            Get-ChildItem -LiteralPath $p -Filter '*.ps1' -File | ForEach-Object { . $_.FullName }
        }
    }
    if (-not (Get-Command -Name 'New-MWEGroup' -ErrorAction SilentlyContinue)) {
        $fn = Get-ChildItem -LiteralPath $moduleRoot -Recurse -Filter 'New-MWEGroup.ps1' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $fn) { throw "Test setup failed: could not locate New-MWEGroup.ps1 under $moduleRoot" }
        . $fn.FullName
    }

    # Ensure a command exists for the safety net mock (Graph).
    if (-not (Get-Command -Name 'Invoke-MgGraphRequest' -ErrorAction SilentlyContinue)) {
        function Invoke-MgGraphRequest { param(); throw "Invoke-MgGraphRequest stub executed (should be mocked)." }
    }

    # ModuleName for module-scoped mocks (if applicable)
    $script:ModuleName = (Get-Module -Name 'MWE' -ErrorAction SilentlyContinue | Select-Object -First 1).Name

    $script:sku = 'ENTERPRISEPACK'
    $script:roleName = 'Security Reader'
}

Describe 'New-MWEGroup' {

    BeforeEach {
        # Safety net: if anything tries to call Graph directly, fail immediately.
        Mock -CommandName Invoke-MgGraphRequest -MockWith { throw 'SAFETY: Invoke-MgGraphRequest was called unexpectedly.' }
        if ($script:ModuleName) {
            Mock -ModuleName $script:ModuleName -CommandName Invoke-MgGraphRequest -MockWith { throw 'SAFETY: Invoke-MgGraphRequest was called unexpectedly.' }
        }
    }

    Context 'Must-have: parameter-set contract (non-interactive)' {

        It 'LICENSE: throws when SkuPartNumber is empty (avoids mandatory prompt)' {
            { New-MWEGroup -SkuPartNumber '' -Mock } | Should -Throw
        }

        It 'ENTRAROLE: throws when RoleName is empty (avoids mandatory prompt)' {
            { New-MWEGroup -RoleName '' -AssignmentType 'Active' } | Should -Throw
        }

        It 'ENTRAROLE: throws when AssignmentType is empty/invalid (avoids mandatory prompt)' {
            { New-MWEGroup -RoleName $script:roleName -AssignmentType '' } | Should -Throw
        }
    }

    Context 'Must-have: orchestration preconditions and call flow' {

        BeforeEach {
            # Default deny: any unexpected command routed via Invoke-MWECommand should fail.
            $script:CommandCalls = @()
            $mockBody = {
                param([string]$Command, [hashtable]$Splat)
                $script:CommandCalls += $Command
                switch ($Command) {
                    'Get-MgSubscribedSku' { [pscustomobject]@{ SkuPartNumber = @($script:sku) } }
                    'Assert-MWEGroupParameters' { $null }
                    'Assert-MWEExistingGroup' { throw 'exists' }
                    default { throw "UNEXPECTED Invoke-MWECommand -Command '$Command' in this test." }
                }
            }

            Mock -CommandName Invoke-MWECommand -MockWith $mockBody
            if ($script:ModuleName) { Mock -ModuleName $script:ModuleName -CommandName Invoke-MWECommand -MockWith $mockBody }
        }

        It 'Stops early when Assert-MWEExistingGroup throws (no create, no side-effects)' {
            { New-MWEGroup -SkuPartNumber $script:sku -Mock -Confirm:$false } | Should -Throw -ExpectedMessage '*exists*'

            $script:CommandCalls | Should -Contain 'Assert-MWEExistingGroup'
            $script:CommandCalls | Should -Not -Contain 'New-MWEGroupResource'
            $script:CommandCalls | Should -Not -Contain 'Set-MWEGroupLicenseAssignment'
            $script:CommandCalls | Should -Not -Contain 'Set-MWEGroupEntraRoleAssignment'
        }
    }

    Context 'Must-have: LICENSE intent flow' {

        BeforeEach {
            $script:newGroup = [pscustomobject]@{ Id = 'G-1'; DisplayName = 'U-LICENSE-ENTERPRISEPACK' }
            $script:CommandCalls = @()
            $script:LastLicenseSplat = $null

            $mockBody = {
                param([string]$Command, [hashtable]$Splat)
                $script:CommandCalls += $Command
                switch ($Command) {
                    'Get-MgSubscribedSku' { [pscustomobject]@{ SkuPartNumber = @($script:sku, 'OTHER') } }
                    'Assert-MWEGroupParameters' { $null }
                    'Assert-MWEExistingGroup' { $null }
                    'New-MWEGroupResource' { $script:newGroup }
                    'Set-MWEGroupLicenseAssignment' { $script:LastLicenseSplat = $Splat; $null }
                    'Set-MWEGroupEntraRoleAssignment' { throw 'ENTRAROLE path should not be called for LICENSE intent' }
                    default { throw "UNEXPECTED Invoke-MWECommand -Command '$Command' in LICENSE test." }
                }
            }

            Mock -CommandName Invoke-MWECommand -MockWith $mockBody
            if ($script:ModuleName) { Mock -ModuleName $script:ModuleName -CommandName Invoke-MWECommand -MockWith $mockBody }

            Mock -CommandName Write-Information -MockWith { }
            if ($script:ModuleName) { Mock -ModuleName $script:ModuleName -CommandName Write-Information -MockWith { } }
        }

        It 'Creates group and calls Set-MWEGroupLicenseAssignment with GroupId + SkuPartNumber' {
            $result = New-MWEGroup -SkuPartNumber $script:sku -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $script:CommandCalls | Should -Contain 'New-MWEGroupResource'
            $script:CommandCalls | Should -Contain 'Set-MWEGroupLicenseAssignment'

            $script:LastLicenseSplat.GroupId | Should -Be 'G-1'
            $script:LastLicenseSplat.SkuPartNumber | Should -Be $script:sku
        }

        It 'WhatIf: runs without throwing and performs only preflight checks (no direct Graph calls)' {
            { New-MWEGroup -SkuPartNumber $script:sku -WhatIf } | Should -Not -Throw
            $script:CommandCalls | Should -Contain 'Assert-MWEExistingGroup'
        }
    }

    Context 'Must-have: ENTRAROLE intent flow' {

        BeforeEach {
            $script:newGroup = [pscustomobject]@{ Id = 'G-2'; DisplayName = 'U-ENTRAROLE-SecurityReader-ACTIVE' }
            $script:roleDefinitions = @([pscustomobject]@{ DisplayName = $script:roleName })
            $script:directoryRoles = @([pscustomobject]@{ DisplayName = $script:roleName })
            $script:CommandCalls = @()
            $script:LastRoleAssignmentSplat = $null
            $script:LastParamValidationSplat = $null

            $mockBody = {
                param([string]$Command, [hashtable]$Splat)
                $script:CommandCalls += $Command
                switch ($Command) {
                    'Get-MgRoleManagementDirectoryRoleDefinition' { $script:roleDefinitions }
                    'Get-MgDirectoryRole' { $script:directoryRoles }
                    'Assert-MWEGroupParameters' { $script:LastParamValidationSplat = $Splat; $null }
                    'Assert-MWEExistingGroup' { $null }
                    'New-MWEGroupResource' { $script:newGroup }
                    'Set-MWEGroupEntraRoleAssignment' { $script:LastRoleAssignmentSplat = $Splat; $null }
                    'Set-MWEGroupLicenseAssignment' { throw 'LICENSE path should not be called for ENTRAROLE intent' }
                    default { throw "UNEXPECTED Invoke-MWECommand -Command '$Command' in ENTRAROLE test." }
                }
            }

            Mock -CommandName Invoke-MWECommand -MockWith $mockBody
            if ($script:ModuleName) { Mock -ModuleName $script:ModuleName -CommandName Invoke-MWECommand -MockWith $mockBody }

            Mock -CommandName Write-Information -MockWith { }
            if ($script:ModuleName) { Mock -ModuleName $script:ModuleName -CommandName Write-Information -MockWith { } }
        }

        It 'Active: calls Set-MWEGroupEntraRoleAssignment without MaximumActivationHours' {
            New-MWEGroup -RoleName $script:roleName -AssignmentType 'Active' -Confirm:$false | Out-Null

            $script:CommandCalls | Should -Contain 'Set-MWEGroupEntraRoleAssignment'

            $script:LastRoleAssignmentSplat.GroupId | Should -Be 'G-2'
            $script:LastRoleAssignmentSplat.RoleName | Should -Be $script:roleName
            $script:LastRoleAssignmentSplat.AssignmentType | Should -Be 'Active'
            $script:LastRoleAssignmentSplat.ContainsKey('MaximumActivationHours') | Should -BeFalse
        }

        It 'Eligible: defaults MaximumActivationHours to 9 when not provided' {
            New-MWEGroup -RoleName $script:roleName -AssignmentType 'Eligible' -Confirm:$false | Out-Null

            $script:LastRoleAssignmentSplat.AssignmentType | Should -Be 'Eligible'
            $script:LastRoleAssignmentSplat.MaximumActivationHours | Should -Be 9

            $script:LastParamValidationSplat.Intent | Should -Be 'ENTRAROLE'
            $script:LastParamValidationSplat.AssignmentType | Should -Be 'Eligible'
            $script:LastParamValidationSplat.MaximumActivationHours | Should -Be 9
        }

        It 'Active: when MaximumActivationHours is provided, surfaces validation failure and stops' {
            $override = {
                param([string]$Command, [hashtable]$Splat)
                $script:CommandCalls += $Command
                switch ($Command) {
                    'Get-MgRoleManagementDirectoryRoleDefinition' { $script:roleDefinitions }
                    'Get-MgDirectoryRole' { $script:directoryRoles }
                    'Assert-MWEGroupParameters' { throw "Active PIM assignemeent doesn't need MaximumActivationHours to be set." }
                    default { throw "UNEXPECTED Invoke-MWECommand -Command '$Command' after override: $Command" }
                }
            }
            Mock -CommandName Invoke-MWECommand -MockWith $override
            if ($script:ModuleName) { Mock -ModuleName $script:ModuleName -CommandName Invoke-MWECommand -MockWith $override }

            { New-MWEGroup -RoleName $script:roleName -AssignmentType 'Active' -MaximumActivationHours 1 -Confirm:$false } |
                Should -Throw -ExpectedMessage "*doesn't need MaximumActivationHours*"
        }

        It 'WhatIf: runs without throwing and performs only preflight checks (no direct Graph calls)' {
            { New-MWEGroup -RoleName $script:roleName -AssignmentType 'Eligible' -WhatIf } | Should -Not -Throw
            $script:CommandCalls | Should -Contain 'Assert-MWEExistingGroup'
        }
    }

    Context 'Strongly recommended: error propagation (no swallowing)' {

        BeforeEach {
            $script:CommandCalls = @()
            $mockBody = {
                param([string]$Command, [hashtable]$Splat)
                $script:CommandCalls += $Command
                switch ($Command) {
                    'Get-MgSubscribedSku' { [pscustomobject]@{ SkuPartNumber = @($script:sku) } }
                    'Assert-MWEGroupParameters' { $null }
                    'Assert-MWEExistingGroup' { $null }
                    'New-MWEGroupResource' { throw 'create failed' }
                    default { throw "UNEXPECTED Invoke-MWECommand -Command '$Command' in error propagation test." }
                }
            }

            Mock -CommandName Invoke-MWECommand -MockWith $mockBody
            if ($script:ModuleName) { Mock -ModuleName $script:ModuleName -CommandName Invoke-MWECommand -MockWith $mockBody }
        }

        It 'Propagates error from group creation (New-MWEGroupResource)' {
            { New-MWEGroup -SkuPartNumber $script:sku -Confirm:$false } | Should -Throw -ExpectedMessage '*create failed*'
        }

        It 'Propagates error from license assignment helper' {
            $script:newGroup = [pscustomobject]@{ Id = 'G-9'; DisplayName = 'U-LICENSE-ENTERPRISEPACK' }

            $mockBody2 = {
                param([string]$Command, [hashtable]$Splat)
                $script:CommandCalls += $Command
                switch ($Command) {
                    'Get-MgSubscribedSku' { [pscustomobject]@{ SkuPartNumber = @($script:sku) } }
                    'Assert-MWEGroupParameters' { $null }
                    'Assert-MWEExistingGroup' { $null }
                    'New-MWEGroupResource' { $script:newGroup }
                    'Set-MWEGroupLicenseAssignment' { throw 'assign failed' }
                    default { throw "UNEXPECTED Invoke-MWECommand -Command '$Command' in assign propagation test." }
                }
            }

            Mock -CommandName Invoke-MWECommand -MockWith $mockBody2
            if ($script:ModuleName) { Mock -ModuleName $script:ModuleName -CommandName Invoke-MWECommand -MockWith $mockBody2 }

            { New-MWEGroup -SkuPartNumber $script:sku -Confirm:$false } | Should -Throw -ExpectedMessage '*assign failed*'
        }
    }
}
