#requires -Version 7.2
#requires -Modules Pester

BeforeAll {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    . (Join-Path $PSScriptRoot '..\Private\Invoke-NWEWithLazyProperty.ps1')
}

Describe 'Invoke-NWEWithLazyProperty' {
    It 'retries when provided ErrorId pattern matches thrown error message' {
        $attempts = 0
        $result = Invoke-NWEWithLazyProperty -ErrorId 'SubjectNotFound' -TimeoutSeconds 3 -SleepSeconds 1 -ScriptBlock {
            $script:attempts++
            if ($script:attempts -lt 2) { throw [System.Exception]::new('SubjectNotFound') }
            return 'ok'
        }

        $result | Should -Be 'ok'
        $attempts | Should -Be 2
    }

    It 'does not retry when error does not match' {
        { Invoke-NWEWithLazyProperty -ErrorId 'SubjectNotFound' -TimeoutSeconds 1 -SleepSeconds 1 -ScriptBlock { throw [System.Exception]::new('OtherError') } } | Should -Throw
    }
}
