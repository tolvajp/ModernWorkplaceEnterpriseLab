Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    . $PSScriptRoot\TestHelpers.ps1
    Import-MWEModuleUnderTest
}

InModuleScope 'MWE' {

    Describe 'Set-MWEGroupLicenseAssignment' {

        BeforeEach {
            $script:calls = @()

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
                    'Get-MgSubscribedSku' {
                        return @(
                            [pscustomobject]@{
                                SkuPartNumber = 'E5'
                                SkuId         = [guid]'11111111-1111-1111-1111-111111111111'
                            },
                            [pscustomobject]@{
                                SkuPartNumber = 'E3'
                                SkuId         = [guid]'22222222-2222-2222-2222-222222222222'
                            }
                        )
                    }
                    'Set-MgGroupLicense' {
                        return $null
                    }
                    default { throw "Unexpected command in mock: $Command" }
                }
            }
        }

        Context '1) WhatIf gate' {

            It 'Does not call Set-MgGroupLicense when -WhatIf is specified' {
                { Set-MWEGroupLicenseAssignment -GroupId 'G-1' -SkuId ([guid]'11111111-1111-1111-1111-111111111111') -WhatIf } | Should -Not -Throw
                @($script:calls | Where-Object { $_.Command -eq 'Set-MgGroupLicense' }).Count | Should -Be 0
            }
        }

        Context '2) BySkuId happy path' {

            It 'Does not call Get-MgSubscribedSku when -SkuId is provided and calls Set-MgGroupLicense' {
                $skuId = [guid]'11111111-1111-1111-1111-111111111111'
                $null = Set-MWEGroupLicenseAssignment -GroupId 'G-1' -SkuId $skuId

                @($script:calls | Where-Object { $_.Command -eq 'Get-MgSubscribedSku' }).Count | Should -Be 0
                @($script:calls | Where-Object { $_.Command -eq 'Set-MgGroupLicense' }).Count | Should -Be 1
            }
        }

        Context '3) BySkuPartNumber happy path (resolution)' {

            It 'Calls Get-MgSubscribedSku, resolves SkuId, then calls Set-MgGroupLicense' {
                $null = Set-MWEGroupLicenseAssignment -GroupId 'G-1' -SkuPartNumber 'E5'

                $script:calls.Count | Should -Be 2
                $script:calls[0].Command | Should -Be 'Get-MgSubscribedSku'
                $script:calls[1].Command | Should -Be 'Set-MgGroupLicense'

                $call = $script:calls[1]
                $call.Splat.GroupId | Should -Be 'G-1'
                $call.Splat.AddLicenses | Should -Not -BeNullOrEmpty
            }
        }

        Context '4) Unknown SkuPartNumber' {

            It 'Throws when SkuPartNumber is not found in subscribed SKUs' {
                $thrown = $null
                try {
                    Set-MWEGroupLicenseAssignment -GroupId 'G-1' -SkuPartNumber 'DOESNOTEXIST'
                }
                catch {
                    $thrown = $_
                }

                $thrown | Should -Not -BeNullOrEmpty
                $thrown.Exception.Message | Should -Match "No such subscribed SKU found \(SkuPartNumber\): 'DOESNOTEXIST'"

                @($script:calls | Where-Object { $_.Command -eq 'Set-MgGroupLicense' }).Count | Should -Be 0
            }
        }

        Context '5) Set-MgGroupLicense splat shape' {

            It 'Uses expected AddLicenses/RemoveLicenses structure for BySkuId' {
                $skuId = [guid]'22222222-2222-2222-2222-222222222222'
                $null = Set-MWEGroupLicenseAssignment -GroupId 'G-42' -SkuId $skuId

                $call = $script:calls | Where-Object { $_.Command -eq 'Set-MgGroupLicense' } | Select-Object -First 1
                $call | Should -Not -BeNullOrEmpty

                $call.Splat.GroupId | Should -Be 'G-42'
                $call.Splat.AddLicenses.Count | Should -Be 1
                $call.Splat.AddLicenses[0].SkuId | Should -Be $skuId
                $call.Splat.RemoveLicenses.Count | Should -Be 0
            }

            It 'Uses resolved SkuId for BySkuPartNumber' {
                $null = Set-MWEGroupLicenseAssignment -GroupId 'G-9' -SkuPartNumber 'E5'

                $call = $script:calls | Where-Object { $_.Command -eq 'Set-MgGroupLicense' } | Select-Object -First 1
                $call.Splat.GroupId | Should -Be 'G-9'
                $call.Splat.AddLicenses[0].SkuId | Should -Be ([guid]'11111111-1111-1111-1111-111111111111')
                $call.Splat.RemoveLicenses.Count | Should -Be 0
            }
        }

        Context '6) Information stream on success' {

            It 'Writes an information record with GroupId and SkuId' {
                $info = $null
                $skuId = [guid]'22222222-2222-2222-2222-222222222222'

                $null = Set-MWEGroupLicenseAssignment -GroupId 'G-77' -SkuId $skuId -InformationAction Continue -InformationVariable info

                $info | Should -Not -BeNullOrEmpty
                $info.Count | Should -Be 1
                $info[0].MessageData | Should -Match 'Assigned license'
                $info[0].MessageData | Should -Match 'G-77'
                $info[0].MessageData | Should -Match ([regex]::Escape($skuId.ToString()))
            }
        }

        Context '7) Error bubbling' {

            It 'Re-throws errors from Set-MgGroupLicense unchanged' {
                Mock -CommandName Invoke-MWECommand -MockWith {
                    param([string]$Command, [hashtable]$Splat)

                    $script:calls += [pscustomobject]@{ Command = $Command; Splat = $Splat }

                    if ($Command -eq 'Get-MgSubscribedSku') { return @() }
                    if ($Command -eq 'Set-MgGroupLicense') { throw [System.InvalidOperationException]::new('boom-license') }

                    throw "Unexpected command in mock: $Command"
                }

                { Set-MWEGroupLicenseAssignment -GroupId 'G-1' -SkuId ([guid]'11111111-1111-1111-1111-111111111111') } | Should -Throw -ExceptionType ([System.InvalidOperationException])
            }
        }

        Context '8) Call order (BySkuPartNumber)' {

            It 'Calls Get-MgSubscribedSku before Set-MgGroupLicense' {
                $null = Set-MWEGroupLicenseAssignment -GroupId 'G-1' -SkuPartNumber 'E3'

                $script:calls[0].Command | Should -Be 'Get-MgSubscribedSku'
                $script:calls[1].Command | Should -Be 'Set-MgGroupLicense'
            }
        }

        Context '9) ParameterSet enforcement' {

            It 'Throws ParameterBinding when both -SkuId and -SkuPartNumber are specified' {
                { Set-MWEGroupLicenseAssignment -GroupId 'G-1' -SkuId ([guid]'11111111-1111-1111-1111-111111111111') -SkuPartNumber 'E5' } | Should -Throw
            }
        }

        Context '10) ValidateNotNullOrEmpty (SkuPartNumber)' {

            It 'Throws when SkuPartNumber is empty' {
                { Set-MWEGroupLicenseAssignment -GroupId 'G-1' -SkuPartNumber '' } | Should -Throw
            }
        }
    }
}
