#requires -Version 7.2
#requires -Modules Pester

BeforeAll {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    . (Join-Path $PSScriptRoot '..\Private\ConvertTo-NWEStandardizedName.ps1')
    . (Join-Path $PSScriptRoot '..\Private\New-MWEGroupSplat.ps1')
}

Describe 'New-MWEGroupSplat' {
    It 'builds LICENSE group splat with standardized name and mailNickname match' {
        $splat = New-MWEGroupSplat -ParameterSetName LICENSE -SkuPartNumber 'SPE_E5'
        $splat.DisplayName | Should -Be 'U-LICENSE-SPE_E5'
        $splat.MailNickname | Should -Be $splat.DisplayName
        $splat.SecurityEnabled | Should -BeTrue
        $splat.MailEnabled | Should -BeFalse
    }

    It 'builds ENTRAROLE group splat with role-assignable flag' {
        $splat = New-MWEGroupSplat -ParameterSetName ENTRAROLE -RoleName 'Global Administrator' -AssignmentType Eligible
        $splat.DisplayName | Should -Be 'U-ENTRAROLE-GlobalAdministrator-ELIGIBLE'
        $splat.IsAssignableToRole | Should -BeTrue
    }
}
