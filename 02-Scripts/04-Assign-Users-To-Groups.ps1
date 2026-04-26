# ==========================================
# CloudSchool - Assign Users To Groups
# ==========================================

# ==========================================
# Function: Add User To Groups
# ==========================================
function Add-UserToGroups {

    param (
        $User,
        $TargetGroups,
        $GroupLookup,
        $GroupMembersLookup,
        [ref]$Results
    )

    foreach ($groupName in $TargetGroups) {

        $group = $GroupLookup[$groupName]

        if (-not $group) {

            $Results.Value += [PSCustomObject]@{
                UserPrincipalName = $User.UserPrincipalName
                DisplayName       = $User.DisplayName
                EmployeeType      = $User.EmployeeType
                TargetGroup       = $groupName
                Action            = "Check"
                Status            = "Failed"
                Notes             = "Group not found"
            }

        }
        elseif ($GroupMembersLookup[$group.Id] -contains $User.Id) {

            $Results.Value += [PSCustomObject]@{
                UserPrincipalName = $User.UserPrincipalName
                DisplayName       = $User.DisplayName
                EmployeeType      = $User.EmployeeType
                TargetGroup       = $groupName
                Action            = "Skip"
                Status            = "Success"
                Notes             = "Already member"
            }

        }
        else {

            try {
                New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{
                    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($User.Id)"
                }

                $Results.Value += [PSCustomObject]@{
                    UserPrincipalName = $User.UserPrincipalName
                    DisplayName       = $User.DisplayName
                    EmployeeType      = $User.EmployeeType
                    TargetGroup       = $groupName
                    Action            = "Add"
                    Status            = "Success"
                    Notes             = "User added to group"
                }
            }
            catch {
                $Results.Value += [PSCustomObject]@{
                    UserPrincipalName = $User.UserPrincipalName
                    DisplayName       = $User.DisplayName
                    EmployeeType      = $User.EmployeeType
                    TargetGroup       = $groupName
                    Action            = "Add"
                    Status            = "Failed"
                    Notes             = $_.Exception.Message
                }
            }
        }
    }
}

# ==========================================
# Initialize Variables
# ==========================================
$results = @()

# ==========================================
# Load Groups and Build Cache
# ==========================================
$groups = Get-MgGroup -All

$groupLookup = @{}
foreach ($group in $groups) {
    $groupLookup[$group.DisplayName] = $group
}

$groupMembersLookup = @{}
foreach ($group in $groups) {
    $members = Get-MgGroupMember -GroupId $group.Id -All
    $groupMembersLookup[$group.Id] = $members.Id
}

# ==========================================
# Load Users
# ==========================================
$users = Get-MgUser -All -Property "Id,UserPrincipalName,DisplayName,EmployeeType,Department,OnPremisesExtensionAttributes"

# ==========================================
# Process Users
# ==========================================
foreach ($user in $users) {

    $targetGroups = @()

    if ($user.EmployeeType -eq "Student") {

        $grade = $user.OnPremisesExtensionAttributes.ExtensionAttribute1 -replace "Grade", ""
        $division = $user.OnPremisesExtensionAttributes.ExtensionAttribute2 -replace "Division", ""

        $targetGroups += "GRP-Student-Grade-$grade"
        $targetGroups += "GRP-Student-Grade-$grade-$division"
    }
    elseif ($user.EmployeeType -eq "Staff") {

        $department = $user.Department
        $targetGroups += "GRP-Staff-All"
        $targetGroups += "GRP-Staff-$department"
    }
    else {

        $results += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName       = $user.DisplayName
            EmployeeType      = $user.EmployeeType
            TargetGroup       = ""
            Action            = "Skip"
            Status            = "Skipped"
            Notes             = "EmployeeType is not Student or Staff"
        }

        continue
    }

    Add-UserToGroups `
        -User $user `
        -TargetGroups $targetGroups `
        -GroupLookup $groupLookup `
        -GroupMembersLookup $groupMembersLookup `
        -Results ([ref]$results)
}

# ==========================================
# Export Results
# ==========================================
if (-not (Test-Path ".\05-Outputs")) {
    New-Item -ItemType Directory -Path ".\05-Outputs" | Out-Null
}

$outputPath = ".\05-Outputs\group-assignment-results.csv"

$results | Export-Csv $outputPath -NoTypeInformation -Encoding UTF8

$addedCount   = ($results | Where-Object { $_.Action -eq "Add" -and $_.Status -eq "Success" }).Count
$skippedCount = ($results | Where-Object { $_.Action -eq "Skip" }).Count
$failedCount  = ($results | Where-Object { $_.Status -eq "Failed" }).Count

Write-Host "Group assignment completed."
Write-Host "Added: $addedCount"
Write-Host "Skipped: $skippedCount"
Write-Host "Failed: $failedCount"
Write-Host "Detailed results exported to: $outputPath"