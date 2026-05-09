$scriptPath = ".\02-Scripts\06-create-administrative-units.ps1"

$scriptContent = @'
<#
.SYNOPSIS
Creates and populates Microsoft Entra ID Administrative Units for CloudSchool.

.DESCRIPTION
This script reads Administrative Unit definitions from:
03-CSV-Templates/administrative-units.csv

It creates missing Administrative Units and adds matching users based on:
- UserType
- DepartmentFilter

This script does NOT assign admin roles.
This script does NOT delegate permissions.
This script only creates AU boundaries and adds users to those AUs.

.REQUIREMENTS
Connect to Microsoft Graph first with suitable permissions, for example:
Connect-MgGraph -TenantId "<TENANT_ID>" -Scopes "AdministrativeUnit.ReadWrite.All","User.Read.All","Directory.Read.All"
#>

$ErrorActionPreference = "Stop"

$csvPath = ".\03-CSV-Templates\administrative-units.csv"
$outputPath = ".\05-Outputs\administrative-unit-results.csv"

Write-Host "Starting CloudSchool Administrative Unit creation..." -ForegroundColor Cyan

if (-not (Test-Path $csvPath)) {
    throw "CSV file not found: $csvPath"
}

$requiredColumns = @("AUName", "Description", "UserType", "DepartmentFilter")
$auDefinitions = Import-Csv $csvPath

if ($auDefinitions.Count -eq 0) {
    throw "CSV file is empty: $csvPath"
}

foreach ($column in $requiredColumns) {
    if ($column -notin $auDefinitions[0].PSObject.Properties.Name) {
        throw "Missing required CSV column: $column"
    }
}

Write-Host "AU definitions loaded: $($auDefinitions.Count)" -ForegroundColor Green

Write-Host "Fetching users from Microsoft Graph..." -ForegroundColor Cyan

$allUsers = Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,EmployeeType,Department

$students = $allUsers | Where-Object { $_.EmployeeType -eq "Student" }
$staff = $allUsers | Where-Object { $_.EmployeeType -eq "Staff" }

Write-Host "Students fetched: $($students.Count)" -ForegroundColor Green
Write-Host "Staff fetched: $($staff.Count)" -ForegroundColor Green

Write-Host "Fetching existing Administrative Units..." -ForegroundColor Cyan
$existingAUs = Get-MgDirectoryAdministrativeUnit -All -Property Id,DisplayName,Description

$results = foreach ($definition in $auDefinitions) {

    $auName = $definition.AUName.Trim()
    $description = $definition.Description.Trim()
    $userType = $definition.UserType.Trim()
    $departmentFilter = $definition.DepartmentFilter.Trim()

    if ([string]::IsNullOrWhiteSpace($auName)) {
        Write-Warning "Skipping row because AUName is empty."
        continue
    }

    if ($userType -notin @("Student", "Staff")) {
        Write-Warning "Skipping $auName because UserType must be Student or Staff."
        continue
    }

    Write-Host ""
    Write-Host "Processing AU: $auName" -ForegroundColor Yellow

    $au = $existingAUs | Where-Object { $_.DisplayName -eq $auName }

    if ($null -eq $au) {
        $body = @{
            displayName = $auName
            description = $description
        }

        $au = New-MgDirectoryAdministrativeUnit -BodyParameter $body
        $auStatus = "Created"

        $existingAUs += $au
        Write-Host "Created AU: $auName" -ForegroundColor Green
    }
    else {
        $auStatus = "Existed"
        Write-Host "AU already exists: $auName" -ForegroundColor DarkYellow
    }

    $sourceUsers = if ($userType -eq "Student") {
        $students
    }
    else {
        $staff
    }

    if ($departmentFilter -eq "*") {
        $matchingUsers = $sourceUsers
    }
    else {
        $departments = $departmentFilter -split ";" | ForEach-Object { $_.Trim() }

        $matchingUsers = $sourceUsers | Where-Object {
            $_.Department -in $departments
        }
    }

    Write-Host "Matching users found: $($matchingUsers.Count)" -ForegroundColor Cyan

    $existingMembers = Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $au.Id -All -Property Id
    $existingMemberIds = @($existingMembers | ForEach-Object { $_.Id })

    $added = 0
    $skipped = 0
    $failed = 0

    foreach ($user in $matchingUsers) {
        if ($user.Id -in $existingMemberIds) {
            $skipped++
            continue
        }

        try {
            $memberBody = @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
            }

            New-MgDirectoryAdministrativeUnitMemberByRef `
                -AdministrativeUnitId $au.Id `
                -BodyParameter $memberBody

            $added++
        }
        catch {
            $failed++
            Write-Warning "Failed to add user $($user.UserPrincipalName) to $auName. Error: $($_.Exception.Message)"
        }
    }

    [PSCustomObject]@{
        AUName = $auName
        Status = $auStatus
        UserType = $userType
        DepartmentFilter = $departmentFilter
        MatchingUsers = $matchingUsers.Count
        Added = $added
        Skipped = $skipped
        Failed = $failed
    }
}

if (-not (Test-Path ".\05-Outputs")) {
    New-Item -Path ".\05-Outputs" -ItemType Directory | Out-Null
}

$results | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host ""
Write-Host "Administrative Unit processing completed." -ForegroundColor Green
Write-Host "Results saved to: $outputPath" -ForegroundColor Green

$results | Format-Table -AutoSize
'@

Set-Content -Path $scriptPath -Value $scriptContent