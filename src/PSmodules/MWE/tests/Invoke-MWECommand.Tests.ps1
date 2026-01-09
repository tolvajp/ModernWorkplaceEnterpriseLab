
BeforeAll {
    . "$PSScriptRoot\TestHelpers.ps1"
    Import-MWEModuleUnderTest
}

Describe 'Invoke-MWECommand' {

    Context 'Happy path forwarding' {

        It 'Forwards a simple command and returns its output unchanged' {
            $result = Invoke-MWECommand -Command 'Get-Date'
            $result | Should -BeOfType ([datetime])
        }
    }

    Context 'No output behavior' {

        It 'Does not emit output when the invoked command produces none' {
            $result = Invoke-MWECommand -Command 'Write-Verbose' -Splat @{ Message = 'test' }
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Verbose stream forwarding' {

        It 'Forwards verbose output from the invoked command' {
            $verboseOutput = & {
                Invoke-MWECommand -Command 'Write-Verbose' -Splat @{ Message = 'hello' } -Verbose
            } 4>&1

            $verboseOutput | Should -Not -BeNullOrEmpty
            $verboseOutput[0].Message | Should -Match 'hello'
        }
    }

    Context 'Output type integrity' {

        It 'Does not wrap or change the output type' {
            $result = Invoke-MWECommand -Command 'Get-Item' -Splat @{ Path = $PSHOME }
            $result | Should -BeOfType ([System.IO.DirectoryInfo])
        }
    }

    Context 'ShouldProcess / WhatIf support' {

        It 'Honors WhatIf and does not execute the command' {
            $script:executed = $false

            function Test-WhatIfCommand {
                [CmdletBinding(SupportsShouldProcess)]
                param ()
                if ($PSCmdlet.ShouldProcess('test')) {
                    $script:executed = $true
                }
            }

            Invoke-MWECommand -Command 'Test-WhatIfCommand' -WhatIf
            $script:executed | Should -BeFalse
        }
    }

    Context 'Error handling' {

        It 'Throws when the command does not exist' {
            { Invoke-MWECommand -Command 'This-Command-Does-Not-Exist' } | Should -Throw
        }

        It 'Propagates errors thrown by the invoked command' {
            function Test-ThrowingCommand {
                throw 'Boom'
            }

            { Invoke-MWECommand -Command 'Test-ThrowingCommand' } |
                Should -Throw -ErrorMessage '*Boom*'
        }
    }
}
