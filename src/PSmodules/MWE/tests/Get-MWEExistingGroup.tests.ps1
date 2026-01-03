#requires -Version 7.2
#requires -Modules Pester

BeforeAll {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    . (Join-Path $PSScriptRoot '..\Private\ConvertTo-NWEStandardizedName.ps1')
    . (Join-Path $PSScriptRoot '..\Private\New-MWEGroupSplat.ps1')
    . (Join-Path $PSScriptRoot '..\Private\Get-MWEExistingGroup.ps1')
}

Describe 'Get-MWEExistingGroup' {

    BeforeEach {
        Mock -CommandName Get-MgGroup -MockWith { $null }
    }

    It 'queries by derived displayName for LICENSE' {
        Get-MWEExistingGroup -ParameterSetName LICENSE -SkuPartNumber 'SPE_E5' | Should -BeNullOrEmpty
        Assert-MockCalled -CommandName Get-MgGroup -Times 1 -Exactly
    }

    It 'checks eligible then active for ENTRAROLE' {
        $callCount = 0
        Mock -CommandName Get-MgGroup -MockWith {
            $script:callCount++
            if ($script:callCount -eq 1) { return $null }
            return [pscustomobject]@{ Id='g'; DisplayName='U-ENTRAROLE-GlobalAdministrator-ACTIVE' }
        }

        $g = Get-MWEExistingGroup -ParameterSetName ENTRAROLE -RoleName 'Global Administrator'
        $g.DisplayName | Should -Be 'U-ENTRAROLE-GlobalAdministrator-ACTIVE'
        Assert-MockCalled -CommandName Get-MgGroup -Times 2
    }
}
