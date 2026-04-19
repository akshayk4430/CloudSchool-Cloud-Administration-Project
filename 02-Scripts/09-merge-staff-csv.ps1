$staffPath      = ".\03-CSV-Templates\staff.csv"
$attributesPath = ".\03-CSV-Templates\staff-attributes.csv"
$outputPath     = ".\03-CSV-Templates\staff-final.csv"

$staff      = Import-Csv $staffPath
$attributes = Import-Csv $attributesPath

$attrMap = @{}
foreach ($row in $attributes) {
    $attrMap[$row.UserPrincipalName.Trim().ToLower()] = $row
}

$finalRows = foreach ($user in $staff) {
    $upn = $user.UserPrincipalName.Trim().ToLower()

    if (-not $attrMap.ContainsKey($upn)) {
        Write-Host "Missing attribute mapping for: $upn" -ForegroundColor Red
        continue
    }

    $attr = $attrMap[$upn]

    [PSCustomObject]@{
        UserPrincipalName   = $upn
        DisplayName         = $user.DisplayName
        GivenName           = $user.GivenName
        Surname             = $user.Surname
        MailNickname        = $user.MailNickname
        Department          = $user.Department
        EmployeeType        = $user.EmployeeType
        UsageLocation       = $user.UsageLocation
        ExtensionAttribute1 = $attr.ExtensionAttribute1
        ExtensionAttribute2 = $attr.ExtensionAttribute2
    }
}

$finalRows | Export-Csv $outputPath -NoTypeInformation
Write-Host "Created: $outputPath" -ForegroundColor Green