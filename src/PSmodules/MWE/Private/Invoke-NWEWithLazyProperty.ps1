function Invoke-NWEWithLazyProperty {
    <#
    .SYNOPSIS
    Retries a scriptblock when an eventual-consistency error occurs.

    .DESCRIPTION
    This is an eventual consistency / lazy property workaround for Microsoft Graph.
    Retry is controlled explicitly by -ErrorId patterns supplied by the caller.
    This is NOT PIM activation logic; it simply waits for Graph propagation.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ErrorId,

        [Parameter()]
        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 300,

        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$SleepSeconds = 10
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ($true) {
        try {
            return & $ScriptBlock
        }
        catch {
            $fqid = $_.FullyQualifiedErrorId
            $msg  = $_.Exception.Message

            $shouldRetry = $false
            foreach ($pattern in $ErrorId) {
                if (($null -ne $fqid -and $fqid -match $pattern) -or ($null -ne $msg -and $msg -match $pattern)) {
                    $shouldRetry = $true
                    break
                }
            }

            if (-not $shouldRetry) { throw }

            if ((Get-Date) -ge $deadline) { throw }
            Start-Sleep -Seconds $SleepSeconds
        }
    }
}
