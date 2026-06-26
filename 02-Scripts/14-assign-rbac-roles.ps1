# =============================================================================
# 14-assign-rbac-roles.ps1
# CloudSchool - Azure RBAC Role Assignments
# Reads rbac-assignments.csv and assigns Azure RBAC roles to users and groups
# Az module only - no Graph required
# Run from repo root: .\02-Scripts\14-assign-rbac-roles.ps1
# =============================================================================

# --- Paths ---
$csvPath    = "$PSScriptRoot\..\03-CSV-Templates\rbac-assignments.csv"
$outputDir  = "$PSScriptRoot\..\05-Outputs"
$outputFile = "$outputDir\rbac-assignment-results.csv"

# --- Validate CSV exists ---
if (-not (Test-Path $csvPath)) {
    Write-Error "CSV not found at: $csvPath"
    exit 1
}

# --- Ensure output directory exists ---
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# --- Load CSV ---
$assignments = Import-Csv $csvPath
Write-Host "`nLoaded $($assignments.Count) assignments from CSV" -ForegroundColor Cyan

# --- Get Subscription ID ---
$subscription = Get-AzSubscription | Where-Object { $_.Name -eq "CloudSchool-Prod-Subscription" }
if (-not $subscription) {
    Write-Error "Subscription 'CloudSchool-Prod-Subscription' not found. Are you connected via Connect-AzAccount?"
    exit 1
}
$subscriptionId = $subscription.Id
Write-Host "Subscription ID: $subscriptionId" -ForegroundColor Cyan

# --- Results collector ---
$results = @()

# --- Process each assignment ---
foreach ($row in $assignments) {

    $principalName = $row.PrincipalName
    $principalType = $row.PrincipalType
    $roleName      = $row.RoleDefinitionName
    $scopeType     = $row.ScopeType
    $scopeName     = $row.ScopeName

Write-Host "`n--- Processing: $principalName | $roleName | ${scopeType}: $scopeName ---" -ForegroundColor Yellow

    # --- Resolve Principal to ObjectId ---
    $objectId = $null

    try {
        if ($principalType -eq "User") {
            $principal = Get-AzADUser -UserPrincipalName $principalName
            if ($principal) { $objectId = $principal.Id }
        }
        elseif ($principalType -eq "Group") {
            $principal = Get-AzADGroup -DisplayName $principalName
            if ($principal) { $objectId = $principal.Id }
        }
        else {
            Write-Warning "Unknown PrincipalType '$principalType' for $principalName — skipping"
            $results += [PSCustomObject]@{
                PrincipalName      = $principalName
                PrincipalType      = $principalType
                RoleDefinitionName = $roleName
                ScopeType          = $scopeType
                ScopeName          = $scopeName
                Status             = "Skipped"
                Reason             = "Unknown PrincipalType"
            }
            continue
        }
    }
    catch {
        Write-Warning "Error resolving principal '$principalName': $_"
        $results += [PSCustomObject]@{
            PrincipalName      = $principalName
            PrincipalType      = $principalType
            RoleDefinitionName = $roleName
            ScopeType          = $scopeType
            ScopeName          = $scopeName
            Status             = "Failed"
            Reason             = "Error resolving principal: $_"
        }
        continue
    }

    if (-not $objectId) {
        Write-Warning "Principal '$principalName' not found in Azure AD — skipping"
        $results += [PSCustomObject]@{
            PrincipalName      = $principalName
            PrincipalType      = $principalType
            RoleDefinitionName = $roleName
            ScopeType          = $scopeType
            ScopeName          = $scopeName
            Status             = "Skipped"
            Reason             = "Principal not found"
        }
        continue
    }

    # --- Build Scope Path ---
    $scope = $null

    if ($scopeType -eq "Subscription") {
        $scope = "/subscriptions/$subscriptionId"
    }
    elseif ($scopeType -eq "ResourceGroup") {
        $rg = Get-AzResourceGroup -Name $scopeName -ErrorAction SilentlyContinue
        if (-not $rg) {
            Write-Warning "Resource Group '$scopeName' not found — skipping"
            $results += [PSCustomObject]@{
                PrincipalName      = $principalName
                PrincipalType      = $principalType
                RoleDefinitionName = $roleName
                ScopeType          = $scopeType
                ScopeName          = $scopeName
                Status             = "Skipped"
                Reason             = "Resource Group not found"
            }
            continue
        }
        $scope = $rg.ResourceId
    }
    else {
        Write-Warning "Unknown ScopeType '$scopeType' for $principalName — skipping"
        $results += [PSCustomObject]@{
            PrincipalName      = $principalName
            PrincipalType      = $principalType
            RoleDefinitionName = $roleName
            ScopeType          = $scopeType
            ScopeName          = $scopeName
            Status             = "Skipped"
            Reason             = "Unknown ScopeType"
        }
        continue
    }

    # --- Check if assignment already exists ---
    $existing = Get-AzRoleAssignment `
        -ObjectId $objectId `
        -RoleDefinitionName $roleName `
        -Scope $scope `
        -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Host "  Already exists — skipping" -ForegroundColor Green
        $results += [PSCustomObject]@{
            PrincipalName      = $principalName
            PrincipalType      = $principalType
            RoleDefinitionName = $roleName
            ScopeType          = $scopeType
            ScopeName          = $scopeName
            Status             = "AlreadyExists"
            Reason             = "Assignment already present"
        }
        continue
    }

    # --- Assign Role ---
    try {
        New-AzRoleAssignment `
            -ObjectId $objectId `
            -RoleDefinitionName $roleName `
            -Scope $scope | Out-Null

        Write-Host "  Assigned: $roleName to $principalName at $scopeType $scopeName" -ForegroundColor Green
        $results += [PSCustomObject]@{
            PrincipalName      = $principalName
            PrincipalType      = $principalType
            RoleDefinitionName = $roleName
            ScopeType          = $scopeType
            ScopeName          = $scopeName
            Status             = "Assigned"
            Reason             = ""
        }
    }
    catch {
        Write-Warning "  Failed to assign $roleName to $principalName : $_"
        $results += [PSCustomObject]@{
            PrincipalName      = $principalName
            PrincipalType      = $principalType
            RoleDefinitionName = $roleName
            ScopeType          = $scopeType
            ScopeName          = $scopeName
            Status             = "Failed"
            Reason             = $_.ToString()
        }
    }
}

# --- Export Results ---
$results | Export-Csv $outputFile -NoTypeInformation
Write-Host "`nResults exported to: $outputFile" -ForegroundColor Cyan

# --- Summary ---
$assigned      = ($results | Where-Object { $_.Status -eq "Assigned" }).Count
$alreadyExists = ($results | Where-Object { $_.Status -eq "AlreadyExists" }).Count
$skipped       = ($results | Where-Object { $_.Status -eq "Skipped" }).Count
$failed        = ($results | Where-Object { $_.Status -eq "Failed" }).Count

Write-Host "`n============= SUMMARY =============" -ForegroundColor Cyan
Write-Host "  Assigned      : $assigned"  -ForegroundColor Green
Write-Host "  Already Exists: $alreadyExists" -ForegroundColor Yellow
Write-Host "  Skipped       : $skipped"   -ForegroundColor Yellow
Write-Host "  Failed        : $failed"    -ForegroundColor Red
Write-Host "===================================" -ForegroundColor Cyan
