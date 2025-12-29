#requires -Version 7.2
#requires -Modules Pester

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    # Load the function under test
    $sutPath = Join-Path -Path $PSScriptRoot -ChildPath '..\New-MWEGroup.ps1'
    . $sutPath
}

Describe 'New-MWEGroup' {

    BeforeEach {
        # Default behavior: group does not exist
        Mock -CommandName Get-MgGroup -MockWith { $null }

        # Default create mock
        Mock -CommandName New-MgGroup -MockWith {
            [pscustomobject]@{
                Id          = '00000000-0000-0000-0000-000000000000'
                DisplayName = $DisplayName
            }
        }
    }

    Context 'Naming and normalization' {

        It 'creates a normalized display name based on parameter set and Name' {
            $result = New-MWEGroup -Name 'Test@01'

            $result.DisplayName | Should -Be 'U-DUMMY-Test01'
        }

        It 'throws if the normalized name exceeds 64 characters' {
            $longName = 'A' * 100

            { New-MWEGroup -Name $longName } | Should -Throw
        }
    }

    Context 'Duplicate detection' {

        It 'throws if a group with the same displayName already exists' {
            Mock -CommandName Get-MgGroup -MockWith {
                [pscustomobject]@{
                    Id          = 'existing-id'
                    DisplayName = 'U-DUMMY-Test01'
                }
            }

            { New-MWEGroup -Name 'Test01' } | Should -Throw
        }
    }

    Context 'WhatIf behavior' {

        It 'does not call New-MgGroup when -WhatIf is used' {
            Mock -CommandName Get-MgGroup -MockWith { $null }
            Mock -CommandName New-MgGroup -MockWith {
                throw 'New-MgGroup should not be called when -WhatIf is used'
            }

            $result = New-MWEGroup -Name 'Test01' -WhatIf

            $result | Should -BeNullOrEmpty
            Should -Invoke -CommandName New-MgGroup -Times 0 -Exactly
        }

        It 'still throws when the group already exists even with -WhatIf' {
            Mock -CommandName Get-MgGroup -MockWith {
                [pscustomobject]@{
                    Id          = 'existing-id'
                    DisplayName = 'U-DUMMY-Test01'
                }
            }

            { New-MWEGroup -Name 'Test01' -WhatIf } | Should -Throw
        }
    }
}
