# 04-Create-Groups.ps1
# Purpose: Create required CloudSchool Entra ID groups from CSV source of truth

$CsvPath = ".\03-CSV-Templates\groups-required.csv"
$OutputPath = ".\05-Outputs\group-creation-results.csv"

# Ensure output folder exists
$OutputFolder = Split-Path $OutputPath

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

# Import required groups
$RequiredGroups = Import-Csv $CsvPath

# Basic validation
if (-not $RequiredGroups) {
    Write-Error "No groups found in CSV file: $CsvPath"
    return
}

# Validate required columns
$RequiredColumns = @(
    "DisplayName",
    "MailNickname",
    "Description",
    "Category"
)

$CsvColumns = $RequiredGroups[0].PSObject.Properties.Name

foreach ($Column in $RequiredColumns) {
    if ($Column -notin $CsvColumns) {
        Write-Error "Missing required CSV column: $Column"
        return
    }
}

Write-Host "Imported $($RequiredGroups.Count) required groups from CSV."

# Fetch existing groups once
$ExistingGroups = Get-MgGroup -All -Property Id,DisplayName

# Create lookup table for fast comparison
$ExistingGroupLookup = @{}

foreach ($ExistingGroup in $ExistingGroups) {
    $ExistingGroupLookup[$ExistingGroup.DisplayName] = $ExistingGroup
}

Write-Host "Fetched $($ExistingGroups.Count) groups from Entra ID."

# Compare required groups with existing groups
$Results = @()

foreach ($Group in $RequiredGroups) {

    $DisplayName = $Group.DisplayName

    if ($ExistingGroupLookup.ContainsKey($DisplayName)) {

        Write-Host "SKIP: $DisplayName already exists"

        $Results += [PSCustomObject]@{
            DisplayName = $DisplayName
            Status      = "Skipped"
            Message     = "Group already exists"
        }

    }
else {

    try {
        New-MgGroup `
            -DisplayName $Group.DisplayName `
            -MailEnabled:$false `
            -MailNickname $Group.MailNickname `
            -SecurityEnabled:$true `
            -Description $Group.Description `
            -ErrorAction Stop | Out-Null

        Write-Host "CREATED: $DisplayName"

        $Results += [PSCustomObject]@{
            DisplayName  = $Group.DisplayName
            MailNickname = $Group.MailNickname
            Category     = $Group.Category
            Status       = "Created"
            Message      = "Group created successfully"
        }
    }
    catch {
        Write-Host "FAILED: $DisplayName"

        $Results += [PSCustomObject]@{
            DisplayName  = $Group.DisplayName
            MailNickname = $Group.MailNickname
            Category     = $Group.Category
            Status       = "Failed"
            Message      = $_.Exception.Message
        }
    }
}
}
$Results | Export-Csv $OutputPath -NoTypeInformation

Write-Host ""
Write-Host "Summary:"
$Results | Group-Object Status | Select-Object Name,Count | Format-Table -AutoSize

Write-Host "Results exported to: $OutputPath"