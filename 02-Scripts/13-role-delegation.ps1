<#
.SYNOPSIS
Creates role-assignable groups, syncs members, and assigns Helpdesk Administrator
role scoped to Administrative Units for CloudSchool role delegation.

.DESCRIPTION
This script reads role delegation definitions from:
03-CSV-Templates/role-delegation.csv

For each row it:
1. Checks the AU exists — if not, logs a warning and skips that row
2. Creates the group if it does not exist (as a role-assignable group)
3. Syncs group membership — adds new members, removes members no longer in CSV
4. Assigns the Helpdesk Administrator role to the group, scoped to the AU

This script does NOT create Administrative Units.
If an AU does not exist, run 06-create-administrative-units.ps1 first,
then come back and rerun this script.

.REQUIREMENTS
Connect to Microsoft Graph first:
Connect-MgGraph -Scopes "AdministrativeUnit.ReadWrite.All","User.Read.All","Directory.Read.All","Group.ReadWrite.All","RoleManagement.ReadWrite.Directory"
#>

$ErrorActionPreference = "Stop"

$csvPath    = ".\03-CSV-Templates\role-delegation.csv"
$outputPath = ".\05-Outputs\role-delegation-results.csv"

Write-Host "Starting CloudSchool Role Delegation..." -ForegroundColor Cyan

# --- Validate CSV ---
if (-not (Test-Path $csvPath)) {
    throw "CSV file not found: $csvPath"
}

$delegations = Import-Csv $csvPath

if ($delegations.Count -eq 0) {
    throw "CSV file is empty: $csvPath"
}

$requiredColumns = @("GroupName", "GroupDescription", "AUName", "RoleName", "MemberUPN")
foreach ($col in $requiredColumns) {
    if ($col -notin $delegations[0].PSObject.Properties.Name) {
        throw "Missing required CSV column: $col"
    }
}

Write-Host "Loaded $($delegations.Count) rows from CSV." -ForegroundColor Green

# --- Fetch existing data once ---
Write-Host "Fetching Administrative Units..." -ForegroundColor Cyan
$existingAUs = Get-MgDirectoryAdministrativeUnit -All -Property Id,DisplayName

Write-Host "Fetching existing Groups..." -ForegroundColor Cyan
$existingGroups = Get-MgGroup -All -Property Id,DisplayName,IsAssignableToRole

# Fetch staff only — filtered by employeeType
# This avoids fetching all 556 users when we only need staff
Write-Host "Fetching users..." -ForegroundColor Cyan
$staffUsers = Get-MgUser -All `
    -Property Id,DisplayName,UserPrincipalName

Write-Host "Staff users fetched: $($staffUsers.Count)" -ForegroundColor Green

Write-Host "Fetching Helpdesk Administrator role definition..." -ForegroundColor Cyan
$helpdeskRole = Get-MgRoleManagementDirectoryRoleDefinition -All | `
    Where-Object { $_.DisplayName -eq "Helpdesk Administrator" }

if ($null -eq $helpdeskRole) {
    throw "Could not find 'Helpdesk Administrator' role definition in this tenant. The role may have been renamed by Microsoft. Check Entra ID > Roles and update the role name in this script."
}

Write-Host "Role found: $($helpdeskRole.DisplayName) ($($helpdeskRole.Id))" -ForegroundColor Green

# --- Build lookup hashtables ---
# Key = DisplayName, Value = full object (includes Id)
$auLookup    = @{}
foreach ($au in $existingAUs)    { $auLookup[$au.DisplayName]           = $au }

$groupLookup = @{}
foreach ($g in $existingGroups)  { $groupLookup[$g.DisplayName]         = $g }

$userLookup  = @{}
foreach ($u in $staffUsers)      { $userLookup[$u.UserPrincipalName]    = $u }

# --- Group CSV rows by GroupName ---
# Each entry has .Name (the GroupName) and .Group (all rows for that group)
# This means if a group has 2 members in future, both are handled in one pass
$groupedByGroup = $delegations | Group-Object -Property GroupName

$results = @()

foreach ($groupEntry in $groupedByGroup) {

    $groupName = $groupEntry.Name

    # Get group settings from any row — AU name, description, role are
    # the same across all rows for the same group, so we just use the first
    $groupSettings    = $groupEntry.Group[0]
    $groupDescription = $groupSettings.GroupDescription.Trim()
    $auName           = $groupSettings.AUName.Trim()
    $roleName         = $groupSettings.RoleName.Trim()

    Write-Host ""
    Write-Host "Processing: $groupName" -ForegroundColor Yellow

    # --- Check AU exists ---
    if (-not $auLookup.ContainsKey($auName)) {
        Write-Warning "AU not found: '$auName'. Skipping '$groupName'. Run 06-create-administrative-units.ps1 first, then rerun this script."
        $results += [PSCustomObject]@{
            GroupName      = $groupName
            AUName         = $auName
            Status         = "Skipped"
            Message        = "AU not found - run AU script first"
            MembersAdded   = 0
            MembersRemoved = 0
            RoleAssigned   = "No"
        }
        continue
    }

    $au = $auLookup[$auName]

    # --- Create group if it does not exist ---
    $groupStatus = "Existed"

    if (-not $groupLookup.ContainsKey($groupName)) {
        try {
            # Strip all non-alphanumeric characters for MailNickname
            # Entra ID requires this field even for non-mail groups
            $mailNickname = ($groupName -replace "[^a-zA-Z0-9]", "")

            $newGroup = New-MgGroup `
                -DisplayName $groupName `
                -Description $groupDescription `
                -MailEnabled:$false `
                -MailNickname $mailNickname `
                -SecurityEnabled:$true `
                -IsAssignableToRole:$true `
                -ErrorAction Stop

            $groupLookup[$groupName] = $newGroup
            $groupStatus = "Created"
            Write-Host "  Group created: $groupName" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to create group '$groupName': $($_.Exception.Message)"
            $results += [PSCustomObject]@{
                GroupName      = $groupName
                AUName         = $auName
                Status         = "Failed"
                Message        = "Group creation failed: $($_.Exception.Message)"
                MembersAdded   = 0
                MembersRemoved = 0
                RoleAssigned   = "No"
            }
            continue
        }
    }
    else {
        Write-Host "  Group already exists: $groupName" -ForegroundColor DarkYellow
    }

    $group = $groupLookup[$groupName]

    # --- Sync members ---
    # Desired = everyone listed in the CSV for this group
    $desiredUPNs = @($groupEntry.Group | ForEach-Object { $_.MemberUPN.Trim() })

    # Current = everyone currently in the group in Entra ID
    $existingMembers   = Get-MgGroupMember -GroupId $group.Id -All -Property Id
    $existingMemberIds = @($existingMembers | ForEach-Object { $_.Id })

    $added   = 0
    $removed = 0

    # ADD: in CSV but not in group
    foreach ($upn in $desiredUPNs) {
        if (-not $userLookup.ContainsKey($upn)) {
            Write-Warning "  User not found in staff list: '$upn' — skipping. Check the UPN in role-delegation.csv."
            continue
        }
        $user = $userLookup[$upn]
        if ($user.Id -notin $existingMemberIds) {
            try {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id -ErrorAction Stop
                $added++
                Write-Host "  Added: $upn" -ForegroundColor Green
            }
            catch {
                Write-Warning "  Failed to add '$upn': $($_.Exception.Message)"
            }
        }
        else {
            Write-Host "  Already member: $upn" -ForegroundColor DarkYellow
        }
    }

    # REMOVE: in group but not in CSV
    $desiredUserIds = @($desiredUPNs | ForEach-Object {
        if ($userLookup.ContainsKey($_)) { $userLookup[$_].Id }
    })

    foreach ($memberId in $existingMemberIds) {
        if ($memberId -notin $desiredUserIds) {
            try {
                Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $memberId -ErrorAction Stop
                $removed++
                Write-Host "  Removed member: $memberId" -ForegroundColor Red
            }
            catch {
                Write-Warning "  Failed to remove member '$memberId': $($_.Exception.Message)"
            }
        }
    }

    # --- Assign role scoped to AU ---
    $roleAssigned = "No"

    try {
        # Check if this exact assignment already exists
        # Filters by role definition ID and group ID
        $existingAssignments = Get-MgRoleManagementDirectoryRoleAssignment `
            -Filter "roleDefinitionId eq '$($helpdeskRole.Id)' and principalId eq '$($group.Id)'" `
            -ErrorAction Stop

        # Check if it is scoped to this specific AU
        $alreadyScoped = $existingAssignments | Where-Object {
            $_.DirectoryScopeId -eq "/administrativeUnits/$($au.Id)"
        }

        if ($null -eq $alreadyScoped) {
            New-MgRoleManagementDirectoryRoleAssignment `
                -RoleDefinitionId $helpdeskRole.Id `
                -PrincipalId $group.Id `
                -DirectoryScopeId "/administrativeUnits/$($au.Id)" `
                -ErrorAction Stop

            $roleAssigned = "Assigned"
            Write-Host "  Role assigned: Helpdesk Administrator scoped to $auName" -ForegroundColor Green
        }
        else {
            $roleAssigned = "Already Existed"
            Write-Host "  Role assignment already exists — skipping" -ForegroundColor DarkYellow
        }
    }
    catch {
        Write-Warning "  Failed to assign role for '$groupName': $($_.Exception.Message)"
        $roleAssigned = "Failed"
    }

    $results += [PSCustomObject]@{
        GroupName      = $groupName
        AUName         = $auName
        Status         = $groupStatus
        Message        = "OK"
        MembersAdded   = $added
        MembersRemoved = $removed
        RoleAssigned   = $roleAssigned
    }
}

# --- Export results ---
if (-not (Test-Path ".\05-Outputs")) {
    New-Item -Path ".\05-Outputs" -ItemType Directory | Out-Null
}

$results | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host ""
Write-Host "Role delegation completed." -ForegroundColor Cyan
Write-Host "Results saved to: $outputPath" -ForegroundColor Cyan
Write-Host ""
$results | Format-Table -AutoSize
