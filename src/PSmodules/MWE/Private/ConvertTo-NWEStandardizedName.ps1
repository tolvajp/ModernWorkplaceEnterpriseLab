function ConvertTo-NWEStandardizedName {
    <#
    .SYNOPSIS
    Standardizes a name to the allowed character set.

    .DESCRIPTION
    Removes any character not in [A-Z a-z 0-9 _ -] and enforces a maximum length.
    This is used for deterministic group naming (DEC-0004).
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$InputName,

        [Parameter()]
        [ValidateRange(1, 1024)]
        [int]$MaxLength = 64
    )

    $standardizedName = $InputName -replace '[^a-zA-Z0-9_-]', ''

    if ($standardizedName.Length -gt $MaxLength) {
        throw "Normalized group name '$standardizedName' is longer than 64 characters. Shorten the input."
    }

    return $standardizedName
}
