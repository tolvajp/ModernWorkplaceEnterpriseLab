Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    . $PSScriptRoot\TestHelpers.ps1
    Import-MWEModuleUnderTest
}

InModuleScope 'MWE' {

    Describe 'Assert-MWEGroupParameters' {

        Context 'Intent contract' {

            It 'Throws when -Intent is missing/empty/whitespace' -TestCases @(
                @{ Case = 'Missing';    Splat = @{ Intent = $null } }
                @{ Case = 'Empty';      Splat = @{ Intent = '' } }
                @{ Case = 'Whitespace'; Splat = @{ Intent = '   ' } }
            ) {
                param($Case, $Splat)

                { Assert-MWEGroupParameters @Splat } | Should -Throw
            }

            It 'Throws when -Intent is invalid (ValidateSet)' {
                { Assert-MWEGroupParameters -Intent 'FOO' } | Should -Throw
            }
        }

        Context 'LICENSE intent' {

            It 'Does not throw when Intent=LICENSE and SkuPartNumber is valid and present in AvailableSkuPartNumbers' {
                $splat = @{
                    Intent                 = 'LICENSE'
                    SkuPartNumber          = 'E5'
                    AvailableSkuPartNumbers = @('E3','E5')
                }

                { Assert-MWEGroupParameters @splat } | Should -Not -Throw
            }

            It 'Throws when Intent=LICENSE and SkuPartNumber is missing (no Mock)' {
                $splat = @{
                    Intent                 = 'LICENSE'
                    AvailableSkuPartNumbers = @('E3','E5')
                }

                { Assert-MWEGroupParameters @splat } | Should -Throw
            }

            It 'Throws when Intent=LICENSE and SkuPartNumber is empty/whitespace (no Mock)' -TestCases @(
                @{ Case = 'Empty';      Value = '' }
                @{ Case = 'Whitespace'; Value = '   ' }
            ) {
                param($Case, $Value)

                $splat = @{
                    Intent                 = 'LICENSE'
                    SkuPartNumber          = $Value
                    AvailableSkuPartNumbers = @('E3','E5')
                }

                { Assert-MWEGroupParameters @splat } | Should -Throw
            }

            It 'Throws when Intent=LICENSE and -Mock is specified but SkuPartNumber is missing (current contract)' {
                $splat = @{
                    Intent = 'LICENSE'
                    Mock   = $true
                }

                { Assert-MWEGroupParameters @splat } | Should -Throw
            }
        }

        Context 'ENTRAROLE intent - basic requirements' {

            It 'AssignmentType: missing is allowed, invalid throws' -TestCases @(
                @{ Case = 'Missing'; ExpectThrow = $false; AssignmentType = $null }
                @{ Case = 'Invalid'; ExpectThrow = $true;  AssignmentType = 'Foo' }
            ) {
                param($Case, $ExpectThrow, $AssignmentType)

                $splat = @{
                    Intent                     = 'ENTRAROLE'
                    RoleName                   = 'Security Reader'
                    RoleDefinitionDisplayNames = @('Security Reader')
                    DirectoryRoleDisplayNames  = @('Security Reader')
                }

                if ($null -ne $AssignmentType) { $splat.AssignmentType = $AssignmentType }

                if ($ExpectThrow) {
                    { Assert-MWEGroupParameters @splat } | Should -Throw
                }
                else {
                    { Assert-MWEGroupParameters @splat } | Should -Not -Throw
                }
            }


                { Assert-MWEGroupParameters @splat } | Should -Throw
            }

            It 'Throws when Intent=ENTRAROLE and RoleName is missing/empty/whitespace' -TestCases @(
                @{ Case = 'Missing';    RoleName = $null }
                @{ Case = 'Empty';      RoleName = '' }
                @{ Case = 'Whitespace'; RoleName = '   ' }
            ) {
                param($Case, $RoleName)

                $splat = @{
                    Intent                    = 'ENTRAROLE'
                    AssignmentType            = 'Active'
                    RoleDefinitionDisplayNames = @('Security Reader')
                    DirectoryRoleDisplayNames  = @('Security Reader')
                }

                if ($null -ne $RoleName) { $splat.RoleName = $RoleName }

                { Assert-MWEGroupParameters @splat } | Should -Throw
            }

            It 'Throws when Intent=ENTRAROLE and role lists are missing/empty' -TestCases @(
                @{ Case = 'RoleDefinitionDisplayNames missing'; RoleDef = $null;               DirRoles = @('Security Reader') }
                @{ Case = 'DirectoryRoleDisplayNames missing';  RoleDef = @('Security Reader'); DirRoles = $null }
                @{ Case = 'RoleDefinitionDisplayNames empty';   RoleDef = @();                 DirRoles = @('Security Reader') }
                @{ Case = 'DirectoryRoleDisplayNames empty';    RoleDef = @('Security Reader'); DirRoles = @() }
            ) {
                param($Case, $RoleDef, $DirRoles)

                $splat = @{
                    Intent         = 'ENTRAROLE'
                    AssignmentType = 'Active'
                    RoleName       = 'Security Reader'
                }

                if ($null -ne $RoleDef)  { $splat.RoleDefinitionDisplayNames = $RoleDef }
                if ($null -ne $DirRoles) { $splat.DirectoryRoleDisplayNames  = $DirRoles }

                { Assert-MWEGroupParameters @splat } | Should -Throw
            }
        }

        Context 'ENTRAROLE intent - Active vs Eligible' {

            It 'Does not throw for Active assignment when MaximumActivationHours is not provided' {
                $splat = @{
                    Intent                    = 'ENTRAROLE'
                    AssignmentType            = 'Active'
                    RoleName                  = 'Security Reader'
                    RoleDefinitionDisplayNames = @('Security Reader')
                    DirectoryRoleDisplayNames  = @('Security Reader')
                }

                { Assert-MWEGroupParameters @splat } | Should -Not -Throw
            }

            It 'Throws for Active assignment when MaximumActivationHours is provided' {
                $splat = @{
                    Intent                    = 'ENTRAROLE'
                    AssignmentType            = 'Active'
                    RoleName                  = 'Security Reader'
                    RoleDefinitionDisplayNames = @('Security Reader')
                    DirectoryRoleDisplayNames  = @('Security Reader')
                    MaximumActivationHours     = 4
                }

                { Assert-MWEGroupParameters @splat } | Should -Throw
            }

            It 'Eligible assignment requires MaximumActivationHours (missing throws, present does not throw)' -TestCases @(
                @{ Case = 'Missing'; HasHours = $false }
                @{ Case = 'Present'; HasHours = $true }
            ) {
                param($Case, $HasHours)

                $splat = @{
                    Intent                    = 'ENTRAROLE'
                    AssignmentType            = 'Eligible'
                    RoleName                  = 'Security Reader'
                    RoleDefinitionDisplayNames = @('Security Reader')
                    DirectoryRoleDisplayNames  = @('Security Reader')
                }

                if ($HasHours) { $splat.MaximumActivationHours = 4 }

                if ($HasHours) {
                    { Assert-MWEGroupParameters @splat } | Should -Not -Throw
                }
                else {
                    { Assert-MWEGroupParameters @splat } | Should -Throw
                }
            }
        }
    }
