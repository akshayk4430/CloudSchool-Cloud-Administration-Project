$inputPath  = ".\03-CSV-Templates\staff-only-export.csv"
$outputPath = ".\03-CSV-Templates\staff.csv"

$rows = Import-Csv $inputPath

$cleanRows = foreach ($row in $rows) {
    $displayName = $row.DisplayName.Trim()

    # Remove common title prefixes only at the start
    $nameOnly = $displayName -replace '^(Mr|Ms|Mrs|Miss|Dr)\.\s+', ''

    $parts = $nameOnly -split '\s+'

    $givenName = $row.GivenName
    $surname   = $row.Surname

    if ([string]::IsNullOrWhiteSpace($givenName) -and $parts.Count -ge 2) {
        $givenName = $parts[0]
    }

    if ([string]::IsNullOrWhiteSpace($surname) -and $parts.Count -ge 2) {
        $surname = $parts[-1]
    }

    [PSCustomObject]@{
        UserPrincipalName   = $row.UserPrincipalName.Trim().ToLower()
        DisplayName         = $displayName
        GivenName           = $givenName
        Surname             = $surname
        MailNickname        = $row.UserPrincipalName.Split("@")[0].Trim().ToLower()
        Department          = $row.Department.Trim()
        EmployeeType        = "Staff"
        UsageLocation       = if ([string]::IsNullOrWhiteSpace($row.UsageLocation)) { "AE" } else { $row.UsageLocation.Trim().ToUpper() }
        ExtensionAttribute1 = if ([string]::IsNullOrWhiteSpace($row.ExtensionAttribute1)) { "" } else { $row.ExtensionAttribute1.Trim() }
        ExtensionAttribute2 = if ([string]::IsNullOrWhiteSpace($row.ExtensionAttribute2)) { "" } else { $row.ExtensionAttribute2.Trim() }
    }
}

$cleanRows | Export-Csv $outputPath -NoTypeInformation

Write-Host "Created clean file: $outputPath" -ForegroundColor Green