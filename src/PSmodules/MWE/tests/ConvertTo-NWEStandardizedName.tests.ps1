#requires -Version 7.2
#requires -Modules Pester

BeforeAll {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    . (Join-Path $PSScriptRoot '..\Private\ConvertTo-NWEStandardizedName.ps1')
}

Describe 'ConvertTo-NWEStandardizedName' {
    It 'removes characters outside the allowed set' {
        ConvertTo-NWEStandardizedName -InputName 'U-LICENSE-SPE E5!*' | Should -Be 'U-LICENSE-SPEE5'
    }

    It 'throws when result exceeds max length' {
        $inputName = ('A' * 65)
        { ConvertTo-NWEStandardizedName -InputName $inputName -MaxLength 64 } | Should -Throw
    }
}
