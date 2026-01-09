Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    . $PSScriptRoot\TestHelpers.ps1
    Import-MWEModuleUnderTest
}

InModuleScope 'MWE' {

    Describe 'Set-MWEGroupEntraRoleAssignment' {

        BeforeEach {
            $script:calls = @()

            Mock -CommandName Invoke-NWEWithLazyObject -MockWith {
                param(
                    [Parameter(Mandatory)]
                    [scriptblock]$ScriptBlock,

                    [Parameter()]
                    [string[]]$ErrorMessagePatterns,

                    [Parameter()]
                    [string[]]$ErrorIdPatterns,

                    [Parameter()]
                    [int]$TimeoutSeconds,

                    [Parameter()]
                    [int]$SleepSeconds
                )

                & $ScriptBlock
            }

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
                    'Get-MgDirectoryRoleTemplate' { return [pscustomobject]@{ Id = 'T-111'; DisplayName = 'Security Reader' } }
                    'Enable-MgDirectoryRole' { return [pscustomobject]@{ Id = 'DR-222'; DisplayName = 'Security Reader' } }
                    'New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest' { return [pscustomobject]@{ Id = 'REQ-E-1' } }
                    'New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest' { return [pscustomobject]@{ Id = 'REQ-A-1' } }
                    'Set-MWEPimEligibilityMaximumActivationHours' { return $null }
                    default { throw "Unexpected command in mock: $Command" }
                }
            }
        }

        Context '1) WhatIf / ShouldProcess gate' {

            It 'Does not call any Graph commands when -WhatIf is specified' {
                $roleDefs = @([pscustomobject]@{ Id = 'RD-1'; DisplayName = 'Security Reader' })
                $dirRoles = @([pscustomobject]@{ Id = 'DR-1'; DisplayName = 'Security Reader' })

                { Set-MWEGroupEntraRoleAssignment -GroupId 'G-1' -RoleName 'Security Reader' -AssignmentType 'Active' -RoleDefinitions $roleDefs -DirectoryRoles $dirRoles -WhatIf } | Should -Not -Throw

                $script:calls.Count | Should -Be 0
            }
        }

        Context '2-3) Active vs Eligible core paths' {

            It 'Active: calls ACTIVE schedule request and does not call eligible/PIM commands' {
                $roleDefs = @([pscustomobject]@{ Id = 'RD-1'; DisplayName = 'Security Reader' })
                $dirRoles = @([pscustomobject]@{ Id = 'DR-1'; DisplayName = 'Security Reader' })

                $null = Set-MWEGroupEntraRoleAssignment -GroupId 'G-1' -RoleName 'Security Reader' -AssignmentType 'Active' -RoleDefinitions $roleDefs -DirectoryRoles $dirRoles

                ($script:calls.Command -contains 'New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest') | Should -BeTrue
                ($script:calls.Command -contains 'New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest') | Should -BeFalse
                ($script:calls.Command -contains 'Set-MWEPimEligibilityMaximumActivationHours') | Should -BeFalse
            }

            It 'Eligible: calls ELIGIBLE schedule request and then configures PIM maximum activation hours' {
                $roleDefs = @([pscustomobject]@{ Id = 'RD-9'; DisplayName = 'Security Reader' })
                $dirRoles = @([pscustomobject]@{ Id = 'DR-9'; DisplayName = 'Security Reader' })

                $null = Set-MWEGroupEntraRoleAssignment -GroupId 'G-9' -RoleName 'Security Reader' -AssignmentType 'Eligible' -MaximumActivationHours 4 -RoleDefinitions $roleDefs -DirectoryRoles $dirRoles

                $script:calls.Count | Should -BeGreaterThan 0
                $script:calls[0].Command | Should -Be 'New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest'
                $script:calls[-1].Command | Should -Be 'Set-MWEPimEligibilityMaximumActivationHours'

                $pimCall = $script:calls | Where-Object { $_.Command -eq 'Set-MWEPimEligibilityMaximumActivationHours' } | Select-Object -First 1
                $pimCall.Splat.RoleDefinitionId | Should -Be 'RD-9'
                $pimCall.Splat.MaximumActivationHours | Should -Be 4
            }
        }

        Context '4-5) Parameter contract for MaximumActivationHours' {

            It 'Active: throws when MaximumActivationHours is provided' {
                $roleDefs = @([pscustomobject]@{ Id = 'RD-1'; DisplayName = 'Security Reader' })
                $dirRoles = @([pscustomobject]@{ Id = 'DR-1'; DisplayName = 'Security Reader' })

                { Set-MWEGroupEntraRoleAssignment -GroupId 'G-1' -RoleName 'Security Reader' -AssignmentType 'Active' -MaximumActivationHours 4 -RoleDefinitions $roleDefs -DirectoryRoles $dirRoles } | Should -Throw

                $script:calls.Count | Should -Be 0
            }

            It 'Eligible: throws when MaximumActivationHours is missing' {
                $roleDefs = @([pscustomobject]@{ Id = 'RD-1'; DisplayName = 'Security Reader' })
                $dirRoles = @([pscustomobject]@{ Id = 'DR-1'; DisplayName = 'Security Reader' })

                { Set-MWEGroupEntraRoleAssignment -GroupId 'G-1' -RoleName 'Security Reader' -AssignmentType 'Eligible' -RoleDefinitions $roleDefs -DirectoryRoles $dirRoles } | Should -Throw

                $script:calls.Count | Should -Be 0
            }
        }

        Context '6) Error bubbling (no wrapping)' {

            It 'Re-throws errors from schedule request unchanged' {
                Mock -CommandName Invoke-MWECommand -MockWith {
                    param([string]$Command, [hashtable]$Splat)

                    $script:calls += [pscustomobject]@{ Command = $Command; Splat = $Splat }

                    if ($Command -eq 'New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest') { throw [System.InvalidOperationException]::new('boom') }
                    if ($Command -eq 'New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest') { throw [System.InvalidOperationException]::new('boom') }

                    return [pscustomobject]@{ Id = 'ok' }
                }

                $roleDefs = @([pscustomobject]@{ Id = 'RD-1'; DisplayName = 'Security Reader' })
                $dirRoles = @([pscustomobject]@{ Id = 'DR-1'; DisplayName = 'Security Reader' })

                { Set-MWEGroupEntraRoleAssignment -GroupId 'G-1' -RoleName 'Security Reader' -AssignmentType 'Active' -RoleDefinitions $roleDefs -DirectoryRoles $dirRoles } | Should -Throw -ExceptionType ([System.InvalidOperationException])
            }
        }

        Context '7-8) Call order and parameter passing' {

            It 'Does not attempt role activation when DirectoryRoles already contains the role' {
                $roleDefs = @([pscustomobject]@{ Id = 'RD-1'; DisplayName = 'Security Reader' })
                $dirRoles = @([pscustomobject]@{ Id = 'DR-1'; DisplayName = 'Security Reader' })

                $null = Set-MWEGroupEntraRoleAssignment -GroupId 'G-1' -RoleName 'Security Reader' -AssignmentType 'Active' -RoleDefinitions $roleDefs -DirectoryRoles $dirRoles

                ($script:calls.Command -contains 'Get-MgDirectoryRoleTemplate') | Should -BeFalse
                ($script:calls.Command -contains 'Enable-MgDirectoryRole') | Should -BeFalse
            }

            It 'Passes principalId and roleDefinitionId correctly in request body' {
                $roleDefs = @([pscustomobject]@{ Id = 'RD-42'; DisplayName = 'Security Reader' })
                $dirRoles = @([pscustomobject]@{ Id = 'DR-42'; DisplayName = 'Security Reader' })

                $null = Set-MWEGroupEntraRoleAssignment -GroupId 'G-42' -RoleName 'Security Reader' -AssignmentType 'Active' -RoleDefinitions $roleDefs -DirectoryRoles $dirRoles

                $call = $script:calls | Where-Object { $_.Command -eq 'New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest' } | Select-Object -First 1
                $call | Should -Not -BeNullOrEmpty

                $body = $call.Splat.BodyParameter
                $body.principalId | Should -Be 'G-42'
                $body.roleDefinitionId | Should -Be 'RD-42'
                $body.directoryScopeId | Should -Be '/'
                $body.action | Should -Be 'adminAssign'
                $body.scheduleInfo.startDateTime | Should -Not -BeNullOrEmpty
                $body.scheduleInfo.expiration.type | Should -Be 'NoExpiration'
            }
        }

        Context '9) Force activation behavior' {

            It 'With -Force: activates role then performs assignment (activation happens before schedule request)' {
                $roleDefs = @([pscustomobject]@{ Id = 'RD-1'; DisplayName = 'Security Reader' })
                $dirRoles = @([pscustomobject]@{ Id = 'DR-X'; DisplayName = 'Other Role' })

                $null = Set-MWEGroupEntraRoleAssignment -GroupId 'G-1' -RoleName 'Security Reader' -AssignmentType 'Active' -Force -RoleDefinitions $roleDefs -DirectoryRoles $dirRoles

                $script:calls.Count | Should -BeGreaterThan 0
                $script:calls[0].Command | Should -Be 'Get-MgDirectoryRoleTemplate'
                $script:calls[1].Command | Should -Be 'Enable-MgDirectoryRole'

                $enableCall = $script:calls | Where-Object { $_.Command -eq 'Enable-MgDirectoryRole' } | Select-Object -First 1
                $enableCall.Splat.DirectoryRoleTemplateId | Should -Be 'T-111'

                ($script:calls.Command -contains 'New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest') | Should -BeTrue
            }
        }
    }
}
