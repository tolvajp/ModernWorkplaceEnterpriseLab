BeforeAll {
    . "$PSScriptRoot\TestHelpers.ps1"
    Import-MWEModuleUnderTest

    # Force-load the helper into the test scope and keep a stable reference to the function ScriptBlock.
    $moduleRoot = Get-MWEModuleRoot
    $candidatePaths = @(
        (Join-Path -Path $moduleRoot -ChildPath 'Private\Get-MWEGroupDisplayName.ps1'),
        (Join-Path -Path $moduleRoot -ChildPath 'Get-MWEGroupDisplayName.ps1')
    )

    $script:helperPath = $candidatePaths | Where-Object { Test-Path -Path $_ } | Select-Object -First 1
    if (-not $script:helperPath) { throw "Get-MWEGroupDisplayName.ps1 not found under module root: $moduleRoot" }

    . $script:helperPath

    $script:fn = (Get-Command -Name 'Get-MWEGroupDisplayName' -CommandType Function -ErrorAction Stop).ScriptBlock
}

Describe 'Get-MWEGroupDisplayName' {

    Context 'Core naming' {

        It 'Builds the expected name for ENTRAROLE Eligible' {
            $name = & $script:fn -Intent ENTRAROLE -RoleName 'Global Administrator' -AssignmentType Eligible
            $name | Should -BeExactly 'U-ENTRAROLE-GlobalAdministrator-ELIGIBLE'
        }

        It 'Builds the expected name for ENTRAROLE Active' {
            $name = & $script:fn -Intent ENTRAROLE -RoleName 'Security Reader' -AssignmentType Active
            $name | Should -BeExactly 'U-ENTRAROLE-SecurityReader-ACTIVE'
        }
    }

    Context 'Required parameters' {

        It "Throws when SkuPartNumber is missing for LICENSE" {
            $ex = { & $script:fn -Intent LICENSE } | Should -Throw -PassThru
            $ex.Exception.Message | Should -Match "SkuPartNumber is required when Intent is 'LICENSE'"
        }

        It "Throws when RoleName is missing for ENTRAROLE" {
            $ex = { & $script:fn -Intent ENTRAROLE -AssignmentType Eligible } | Should -Throw -PassThru
            $ex.Exception.Message | Should -Match "RoleName is required when Intent is 'ENTRAROLE'"
        }

        It "Throws when AssignmentType is missing for ENTRAROLE" {
            $ex = { & $script:fn -Intent ENTRAROLE -RoleName 'Global Administrator' } | Should -Throw -PassThru
            $ex.Exception.Message | Should -Match "AssignmentType is required when Intent is 'ENTRAROLE'"
        }
    }

    Context 'ValidateSet enforcement' {

        It 'Rejects invalid Intent values (ValidateSet)' {
            { & $script:fn -Intent 'NOPE' -SkuPartNumber 'X' } | Should -Throw
        }

        It 'Rejects invalid AssignmentType values (ValidateSet)' {
            { & $script:fn -Intent ENTRAROLE -RoleName 'Role' -AssignmentType 'Sometimes' } | Should -Throw
        }
    }

    Context 'Normalization and OData-safety' {

        It 'Produces an OData-filter-safe displayName token (no quotes/spaces; allowed charset only)' {
            $name = & $script:fn -Intent LICENSE -SkuPartNumber "SPE'E5"

            $name | Should -Not -Match "'"
            $name | Should -Not -Match '\s'
            $name | Should -Match '^[A-Za-z0-9_-]+$'

            $filter = "displayName eq '$name'"
            $filter | Should -Match "^displayName eq '"
        }

        It 'Trims whitespace around SkuPartNumber' {
            (& $script:fn -Intent LICENSE -SkuPartNumber '  SPE_E5  ') | Should -BeExactly 'U-LICENSE-SPE_E5'
        }
    }

    Context 'Sanitization' {

        It 'Sanitizes invalid characters from SkuPartNumber' {
            $name = & $script:fn -Intent LICENSE -SkuPartNumber 'SPE E5!@#'
            $name | Should -Match '^U-LICENSE-[A-Za-z0-9_-]+$'
            $name | Should -Not -Match '[ !@#]'
        }

        It 'Sanitizes invalid characters from RoleName' {
            $name = & $script:fn -Intent ENTRAROLE -RoleName "Global Admin! @#$%^&*()_+-=[]{};':,./<>?" -AssignmentType Eligible
            $name | Should -Match '^U-ENTRAROLE-[A-Za-z0-9_-]+-ELIGIBLE$'
            $name | Should -Not -Match "[ !@#\$\%\^&\(\)\[\]\{\};':,\.\/<>\\\?]"
        }
    }

    Context 'Length limits' {

        It 'Throws when the generated group name exceeds 64 characters' {
            $role = ('A' * 60)
            { & $script:fn -Intent ENTRAROLE -RoleName $role -AssignmentType Eligible } | Should -Throw
        }
    }
}
