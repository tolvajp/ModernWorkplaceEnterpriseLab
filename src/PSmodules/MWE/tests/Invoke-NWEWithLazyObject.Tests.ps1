
BeforeAll {
    . "$PSScriptRoot\TestHelpers.ps1"
    Import-MWEModuleUnderTest

    # Invoke-NWEWithLazyObject is a private helper; dot-source it for testing.
    $moduleRoot = Get-MWEModuleRoot
    $candidatePaths = @(
        (Join-Path -Path $moduleRoot -ChildPath 'Private\Invoke-NWEWithLazyObject.ps1'),
        (Join-Path -Path $moduleRoot -ChildPath 'Invoke-NWEWithLazyObject.ps1')
    )

    $helperPath = $candidatePaths | Where-Object { Test-Path -Path $_ } | Select-Object -First 1
    if (-not $helperPath) { throw "Invoke-NWEWithLazyObject.ps1 not found under module root: $moduleRoot" }

    . $helperPath
}

Describe 'Invoke-NWEWithLazyObject' {

    BeforeEach {
        # Avoid real sleeping during tests
        Mock -CommandName Start-Sleep -MockWith { }
    }

    Context 'Happy path' {

        It 'Returns the scriptblock output when it succeeds on first try (no retry)' {
            $result = Invoke-NWEWithLazyObject -ScriptBlock { 'ok' } -ErrorMessagePatterns @('x')

            $result | Should -BeExactly 'ok'
            Assert-MockCalled -CommandName Start-Sleep -Times 0 -Exactly -Scope It
        }
    }

    Context 'Preconditions / no-pattern behavior' {

        It 'With empty patterns, does not retry and rethrows immediately on error' {
            { Invoke-NWEWithLazyObject -ScriptBlock { Write-Error -ErrorId 'X' -Message 'fail' -ErrorAction Stop } -ErrorIdPatterns @() -ErrorMessagePatterns @() } |
                Should -Throw

            Assert-MockCalled -CommandName Start-Sleep -Times 0 -Exactly -Scope It
        }
    }

    Context 'Retry decisions' {

        It 'Retries when FullyQualifiedErrorId matches -ErrorIdPatterns and returns on success' {
            $script:attempt = 0

            $result = Invoke-NWEWithLazyObject -ScriptBlock {
                $script:attempt++
                if ($script:attempt -eq 1) {
                    Write-Error -ErrorId 'Request_ResourceNotFound' -Message 'not found' -ErrorAction Stop
                }
                'ok'
            } -ErrorIdPatterns @('Request_ResourceNotFound') -TimeoutSeconds 30 -SleepSeconds 1

            $result | Should -BeExactly 'ok'
            $script:attempt | Should -Be 2
            Assert-MockCalled -CommandName Start-Sleep -Times 1 -Exactly -Scope It
        }

        It 'Retries when Exception.Message matches -ErrorMessagePatterns and returns on success' {
            $script:attempt = 0

            $result = Invoke-NWEWithLazyObject -ScriptBlock {
                $script:attempt++
                if ($script:attempt -eq 1) {
                    Write-Error -ErrorId 'SomeOtherId' -Message 'The object does not exist' -ErrorAction Stop
                }
                'ok'
            } -ErrorMessagePatterns @('does not exist') -TimeoutSeconds 30 -SleepSeconds 1

            $result | Should -BeExactly 'ok'
            $script:attempt | Should -Be 2
            Assert-MockCalled -CommandName Start-Sleep -Times 1 -Exactly -Scope It
        }

        It 'Does not retry when neither FQID nor Message matches; rethrows immediately' {
            { Invoke-NWEWithLazyObject -ScriptBlock {
                    Write-Error -ErrorId 'DifferentId' -Message 'different message' -ErrorAction Stop
                } -ErrorIdPatterns @('WillNotMatch') -ErrorMessagePatterns @('AlsoWillNotMatch') -TimeoutSeconds 30 -SleepSeconds 1
            } | Should -Throw

            Assert-MockCalled -CommandName Start-Sleep -Times 0 -Exactly -Scope It
        }
    }

    Context 'Retry counts and sleep behavior' {

        It 'Retries N times then succeeds; invokes the scriptblock N+1 times' {
            $script:attempt = 0

            $result = Invoke-NWEWithLazyObject -ScriptBlock {
                $script:attempt++
                if ($script:attempt -le 3) {
                    Write-Error -ErrorId 'Request_ResourceNotFound' -Message 'not found' -ErrorAction Stop
                }
                'ok'
            } -ErrorIdPatterns @('Request_ResourceNotFound') -TimeoutSeconds 30 -SleepSeconds 1

            $result | Should -BeExactly 'ok'
            $script:attempt | Should -Be 4
            Assert-MockCalled -CommandName Start-Sleep -Times 3 -Exactly -Scope It
        }

        It 'Calls Start-Sleep only on retry (and not on non-retry errors)' {
            { Invoke-NWEWithLazyObject -ScriptBlock {
                    Write-Error -ErrorId 'DifferentId' -Message 'different message' -ErrorAction Stop
                } -ErrorIdPatterns @('WillNotMatch') -ErrorMessagePatterns @('AlsoWillNotMatch') -TimeoutSeconds 30 -SleepSeconds 1
            } | Should -Throw

            Assert-MockCalled -CommandName Start-Sleep -Times 0 -Exactly -Scope It
        }
    }

    Context 'Parameter validation' {

        It 'Throws when -TimeoutSeconds is outside ValidateRange (too low)' {
            { Invoke-NWEWithLazyObject -ScriptBlock { 'ok' } -ErrorMessagePatterns @('x') -TimeoutSeconds 0 } | Should -Throw
        }

        It 'Throws when -TimeoutSeconds is outside ValidateRange (too high)' {
            { Invoke-NWEWithLazyObject -ScriptBlock { 'ok' } -ErrorMessagePatterns @('x') -TimeoutSeconds 3601 } | Should -Throw
        }

        It 'Throws when -SleepSeconds is outside ValidateRange (too low)' {
            { Invoke-NWEWithLazyObject -ScriptBlock { 'ok' } -ErrorMessagePatterns @('x') -SleepSeconds 0 } | Should -Throw
        }

        It 'Throws when -SleepSeconds is outside ValidateRange (too high)' {
            { Invoke-NWEWithLazyObject -ScriptBlock { 'ok' } -ErrorMessagePatterns @('x') -SleepSeconds 61 } | Should -Throw
        }
    }

    Context 'Null-handling robustness' {

        It 'Does not crash if Exception.Message is $null (should not retry and should throw)' {
            Add-Type -TypeDefinition @"
using System;
public class NullMessageException : Exception {
    public override string Message { get { return null; } }
}
"@ -ErrorAction SilentlyContinue

            { Invoke-NWEWithLazyObject -ScriptBlock { throw ([NullMessageException]::new()) } -ErrorIdPatterns @('WillNotMatch') -ErrorMessagePatterns @('WillNotMatchEither') -TimeoutSeconds 30 -SleepSeconds 1 } |
                Should -Throw

            Assert-MockCalled -CommandName Start-Sleep -Times 0 -Exactly -Scope It
        }

        It 'Does not crash if FullyQualifiedErrorId is missing/unhelpful; message-based retry still works' {
            $script:attempt = 0

            $result = Invoke-NWEWithLazyObject -ScriptBlock {
                $script:attempt++
                if ($script:attempt -eq 1) {
                    throw ([System.Exception]::new('Transient: does not exist yet'))
                }
                'ok'
            } -ErrorMessagePatterns @('does not exist') -TimeoutSeconds 30 -SleepSeconds 1

            $result | Should -BeExactly 'ok'
            $script:attempt | Should -Be 2
            Assert-MockCalled -CommandName Start-Sleep -Times 1 -Exactly -Scope It
        }
    }

    Context 'Multiple patterns' {

        It 'Retries if any pattern matches (among multiple ErrorIdPatterns and ErrorMessagePatterns)' {
            $script:attempt = 0

            $result = Invoke-NWEWithLazyObject -ScriptBlock {
                $script:attempt++
                if ($script:attempt -eq 1) {
                    Write-Error -ErrorId 'Request_ResourceNotFound' -Message 'not found' -ErrorAction Stop
                }
                'ok'
            } -ErrorIdPatterns @('DoesNotMatch', 'Request_ResourceNotFound') -ErrorMessagePatterns @('AlsoNoMatch') -TimeoutSeconds 30 -SleepSeconds 1

            $result | Should -BeExactly 'ok'
            $script:attempt | Should -Be 2
            Assert-MockCalled -CommandName Start-Sleep -Times 1 -Exactly -Scope It
        }
    }
}
