#requires -Version 7.2
#requires -Modules Pester

BeforeAll {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    . (Join-Path $PSScriptRoot '..\Private\Assert-MWEGroupParameters.ps1')
}

Describe 'Assert-MWEGroupParameters' {

    Context 'LICENSE' {
        It 'throws when sku is missing and not mock' {
            Mock -CommandName Get-MgSubscribedSku -MockWith { @([pscustomobject]@{ SkuPartNumber = 'SPE_E5' }) }
            { Assert-MWEGroupParameters -ParameterSetName LICENSE -SkuPartNumber 'NOPE' -Mock:$false } | Should -Throw
        }

        It 'does not throw when mock' {
            Mock -CommandName Get-MgSubscribedSku -MockWith { @() }
            { Assert-MWEGroupParameters -ParameterSetName LICENSE -SkuPartNumber 'ANY' -Mock:$true } | Should -Not -Throw
        }
    }

    Context 'ENTRAROLE' {
        BeforeEach {
            Mock -CommandName Get-MgDirectoryRoleTemplate -MockWith { @([pscustomobject]@{ DisplayName='Global Administrator'; Id='t1' }) }
            Mock -CommandName Get-MgDirectoryRole -MockWith { @([pscustomobject]@{ DisplayName='Global Administrator'; Id='r1' }) }
        }

        It 'throws when role template does not exist' {
            Mock -CommandName Get-MgDirectoryRoleTemplate -MockWith { @([pscustomobject]@{ DisplayName='Other'; Id='t1' }) }
            { Assert-MWEGroupParameters -ParameterSetName ENTRAROLE -RoleName 'Global Administrator' -Force:$true -MaximumActivationHours 9 } | Should -Throw
        }

        It 'throws when role is not active and force is not specified' {
            Mock -CommandName Get-MgDirectoryRole -MockWith { @([pscustomobject]@{ DisplayName='Other'; Id='r1' }) }
            { Assert-MWEGroupParameters -ParameterSetName ENTRAROLE -RoleName 'Global Administrator' -Force:$false -MaximumActivationHours 9 } | Should -Throw
        }

        It 'returns context when valid' {
            $ctx = Assert-MWEGroupParameters -ParameterSetName ENTRAROLE -RoleName 'Global Administrator' -Force:$true -MaximumActivationHours 9
            $ctx.TemplateRoles.Count | Should -Be 1
            $ctx.ActivatedRoles.Count | Should -Be 1
        }
    }
}
