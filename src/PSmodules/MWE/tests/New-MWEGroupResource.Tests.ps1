Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    . $PSScriptRoot\TestHelpers.ps1
    Import-MWEModuleUnderTest
}

InModuleScope 'MWE' {

    Describe 'New-MWEGroupResource' {

        BeforeEach {
            $script:calls = @()

            Mock -CommandName Invoke-MWECommand -MockWith {
                param(
                    [Parameter(Mandatory)]
                    [string]$Command,

                    [Parameter()]
                    [hashtable]$Splat
                )

                $script:calls += [pscustomobject]@{
                    Command = $Command
                    Splat   = $Splat
                }

                switch ($Command) {
                    'Get-MWEGroupDisplayName' { return 'U-LICENSE-E5' }
                    'New-MgGroup' { return [pscustomobject]@{ Id = 'G-123'; DisplayName = $Splat.DisplayName } }
                    default { throw "Unexpected command in mock: $Command" }
                }
            }
        }

        Context 'WhatIf / ShouldProcess gate' {

            It 'Does not call New-MgGroup when -WhatIf is specified' {
                { New-MWEGroupResource -Intent 'LICENSE' -SkuPartNumber 'E5' -WhatIf } | Should -Not -Throw

                @($script:calls | Where-Object { $_.Command -eq 'New-MgGroup' }).Count | Should -Be 0
                @($script:calls | Where-Object { $_.Command -eq 'Get-MWEGroupDisplayName' }).Count | Should -Be 1
            }

            It 'Calls Get-MWEGroupDisplayName first, then New-MgGroup (normal run)' {
                $null = New-MWEGroupResource -Intent 'LICENSE' -SkuPartNumber 'E5'

                $script:calls.Count | Should -Be 2
                $script:calls[0].Command | Should -Be 'Get-MWEGroupDisplayName'
                $script:calls[1].Command | Should -Be 'New-MgGroup'
            }
        }

        Context 'Group resource (splat) composition' {

            It 'Builds correct group splat for LICENSE' {
                $result = New-MWEGroupResource -Intent 'LICENSE' -SkuPartNumber 'E5'

                $result.Id | Should -Be 'G-123'

                $newCall = $script:calls | Where-Object { $_.Command -eq 'New-MgGroup' } | Select-Object -First 1
                $newCall | Should -Not -BeNullOrEmpty

                $newCall.Splat.DisplayName | Should -Be 'U-LICENSE-E5'
                $newCall.Splat.MailEnabled | Should -BeFalse
                $newCall.Splat.SecurityEnabled | Should -BeTrue
                $newCall.Splat.MailNickname | Should -Be 'U-LICENSE-E5'
                $newCall.Splat.IsAssignableToRole | Should -BeFalse
                $newCall.Splat.Description | Should -Be 'License assignment group for E5'
            }

            It 'Builds correct group splat for ENTRAROLE' {
                Mock -CommandName Invoke-MWECommand -MockWith {
                    param([string]$Command, [hashtable]$Splat)

                    $script:calls += [pscustomobject]@{ Command = $Command; Splat = $Splat }

                    switch ($Command) {
                        'Get-MWEGroupDisplayName' { return 'U-ENTRAROLE-GlobalAdministrator-ELIGIBLE' }
                        'New-MgGroup' { return [pscustomobject]@{ Id = 'G-456'; DisplayName = $Splat.DisplayName } }
                        default { throw "Unexpected command in mock: $Command" }
                    }
                }

                $result = New-MWEGroupResource -Intent 'ENTRAROLE' -RoleName 'GlobalAdministrator' -AssignmentType 'Eligible'

                $result.Id | Should -Be 'G-456'

                $newCall = $script:calls | Where-Object { $_.Command -eq 'New-MgGroup' } | Select-Object -First 1
                $newCall.Splat.DisplayName | Should -Be 'U-ENTRAROLE-GlobalAdministrator-ELIGIBLE'
                $newCall.Splat.MailEnabled | Should -BeFalse
                $newCall.Splat.SecurityEnabled | Should -BeTrue
                $newCall.Splat.MailNickname | Should -Be 'U-ENTRAROLE-GlobalAdministrator-ELIGIBLE'
                $newCall.Splat.IsAssignableToRole | Should -BeTrue
                $newCall.Splat.Description | Should -Be 'Entra role assignment group for GlobalAdministrator'
            }
        }

        Context 'Return value and information stream' {

            It 'Returns the object from New-MgGroup unchanged (Id matches)' {
                $group = New-MWEGroupResource -Intent 'LICENSE' -SkuPartNumber 'E5'
                $group.Id | Should -Be 'G-123'
                $group.DisplayName | Should -Be 'U-LICENSE-E5'
            }

            It 'Writes an information record containing the new group Id' {
                $info = $null
                $null = New-MWEGroupResource -Intent 'LICENSE' -SkuPartNumber 'E5' -InformationAction Continue -InformationVariable info

                $info | Should -Not -BeNullOrEmpty
                $info.Count | Should -Be 1
                $info[0].MessageData | Should -Match 'Created new group with Id: G-123'
            }
        }

        Context 'Display name builder parameter passing' {

            It 'Passes Intent and SkuPartNumber to Get-MWEGroupDisplayName for LICENSE' {
                $null = New-MWEGroupResource -Intent 'LICENSE' -SkuPartNumber 'E5'

                $dnCall = $script:calls | Where-Object { $_.Command -eq 'Get-MWEGroupDisplayName' } | Select-Object -First 1
                $dnCall.Splat.Intent | Should -Be 'LICENSE'
                $dnCall.Splat.SkuPartNumber | Should -Be 'E5'
            }

            It 'Includes AssignmentType key (null) in display name splat when ENTRAROLE AssignmentType is omitted' {
                Mock -CommandName Invoke-MWECommand -MockWith {
                    param([string]$Command, [hashtable]$Splat)

                    $script:calls += [pscustomobject]@{ Command = $Command; Splat = $Splat }

                    switch ($Command) {
                        'Get-MWEGroupDisplayName' { return 'U-ENTRAROLE-SecurityReader' }
                        'New-MgGroup' { return [pscustomobject]@{ Id = 'G-789'; DisplayName = $Splat.DisplayName } }
                        default { throw "Unexpected command in mock: $Command" }
                    }
                }

                $null = New-MWEGroupResource -Intent 'ENTRAROLE' -RoleName 'SecurityReader'

                $dnCall = $script:calls | Where-Object { $_.Command -eq 'Get-MWEGroupDisplayName' } | Select-Object -First 1
                $dnCall.Splat.ContainsKey('AssignmentType') | Should -BeTrue
                $dnCall.Splat.AssignmentType | Should -BeNullOrEmpty
            }
        }

        Context 'Error bubbling (no wrapping)' {

            It 'Re-throws errors from New-MgGroup unchanged' {
                Mock -CommandName Invoke-MWECommand -MockWith {
                    param([string]$Command, [hashtable]$Splat)

                    $script:calls += [pscustomobject]@{ Command = $Command; Splat = $Splat }

                    if ($Command -eq 'Get-MWEGroupDisplayName') { return 'U-LICENSE-E5' }
                    if ($Command -eq 'New-MgGroup') { throw [System.InvalidOperationException]::new('boom-new') }

                    throw "Unexpected command in mock: $Command"
                }

                { New-MWEGroupResource -Intent 'LICENSE' -SkuPartNumber 'E5' } | Should -Throw -ExceptionType ([System.InvalidOperationException])
            }

            It 'Re-throws errors from Get-MWEGroupDisplayName unchanged' {
                Mock -CommandName Invoke-MWECommand -MockWith {
                    param([string]$Command, [hashtable]$Splat)

                    $script:calls += [pscustomobject]@{ Command = $Command; Splat = $Splat }

                    if ($Command -eq 'Get-MWEGroupDisplayName') { throw [System.ArgumentException]::new('boom-dn') }
                    if ($Command -eq 'New-MgGroup') { return [pscustomobject]@{ Id = 'G-123' } }

                    throw "Unexpected command in mock: $Command"
                }

                { New-MWEGroupResource -Intent 'LICENSE' -SkuPartNumber 'E5' } | Should -Throw -ExceptionType ([System.ArgumentException])
            }
        }

        Context 'No idempotency/existence lookup in this function' {

            It 'Does not attempt to look up an existing group (no Get-MWEExistingGroup call)' {
                $null = New-MWEGroupResource -Intent 'LICENSE' -SkuPartNumber 'E5'
                ($script:calls.Command -contains 'Get-MWEExistingGroup') | Should -BeFalse
            }
        }
    }
}
