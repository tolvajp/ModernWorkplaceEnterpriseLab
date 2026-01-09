function Invoke-NWEWithLazyObject {
    <#
    .SYNOPSIS
    Retries a scriptblock when an eventual-consistency error occurs.

    .DESCRIPTION
    Eventual consistency / lazy property workaround for Microsoft Graph.
    Retry is controlled explicitly by -ErrorIdPatterns and/or -ErrorMessagePatterns supplied by the caller.
    This is NOT PIM activation logic; it simply waits for Graph propagation.

    .PARAMETER ScriptBlock
    The command(s) to execute and potentially retry.

    .PARAMETER ErrorIdPatterns
    One or more regex patterns matched against $_.FullyQualifiedErrorId.
    If any pattern matches, the invocation is retried until success or timeout.

    .PARAMETER ErrorMessagePatterns
    One or more regex patterns matched against $_.Exception.Message.
    If any pattern matches, the invocation is retried until success or timeout.

    .PARAMETER TimeoutSeconds
    Maximum time window to keep retrying after a retry-eligible error occurs.

    .PARAMETER SleepSeconds
    Delay between retry attempts.

    .EXAMPLE
    Invoke-NWEWithLazyObject -ScriptBlock { Get-MgGroup -GroupId $groupId } -ErrorIdPatterns @('Request_ResourceNotFound')

    .EXAMPLE
    Invoke-NWEWithLazyObject -ScriptBlock { Get-MgDirectoryRole -DirectoryRoleId $roleId } -ErrorMessagePatterns @('Not found','does not exist') -TimeoutSeconds 300 -SleepSeconds 10
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [string[]]$ErrorIdPatterns = @(),

        [Parameter()]
        [string[]]$ErrorMessagePatterns = @(),

        [Parameter()]
        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 300,

        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$SleepSeconds = 2
    )
    $ErrorActionPreference = 'Stop'
    if ($ErrorIdPatterns.Count -eq 0 -and $ErrorMessagePatterns.Count -eq 0) {
        throw "Invoke-NWEWithLazyObject: At least one retry pattern is required. Provide -ErrorIdPatterns and/or -ErrorMessagePatterns."
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    write-verbose -Message "Running scriptblock with lazy object retry logic."
    write-verbose -Message "Timeout at $deadline."
    write-verbose -Message "Scriptblock: $scriptblock"
    
    while ($true) {
        try {
            return & $ScriptBlock
        }
        catch {
            $fqid = $_.FullyQualifiedErrorId
            $msg  = $_.Exception.Message

            write-verbose -Message "Invoke-NWEWithLazyObject: Caught error during invocation."
            write-verbose -Message "  - FullyQualifiedErrorId: $fqid"
            write-verbose -Message "  - Exception.Message: $msg"

            $idMatch = $false
            if ($null -ne $fqid -and $ErrorIdPatterns.Count -gt 0) {
                foreach ($pattern in $ErrorIdPatterns) {
                    if ($fqid -match $pattern) { $idMatch = $true; break }
                }
            }

            $msgMatch = $false
            if ($null -ne $msg -and $ErrorMessagePatterns.Count -gt 0) {
                foreach ($pattern in $ErrorMessagePatterns) {
                    if ($msg -match $pattern) { $msgMatch = $true; break }
                }
            }

            $shouldRetry = ($idMatch -or $msgMatch)

            if (-not $shouldRetry) { throw }

            if ((Get-Date) -ge $deadline) {
                Write-Verbose -Message "Invoke-NWEWithLazyObject: timeout reached ($TimeoutSeconds seconds). Re-throwing last error."
                throw
            }

            Start-Sleep -Seconds $SleepSeconds
        }
    }
}
