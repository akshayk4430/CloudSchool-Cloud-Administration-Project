# 04-assign-groups.ps1

$users = Get-MgUser -All

foreach ($user in $users) {

    # STUDENTS
    if ($user.EmployeeType -eq "Student") {

        $grade = $user.AdditionalProperties["extensionAttribute1"]
        $division = $user.AdditionalProperties["extensionAttribute2"]

        $groupName = "GRP-Grade$grade-$division"

        $group = Get-MgGroup -Filter "displayName eq '$groupName'"

        if ($group) {
            New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
            Write-Host "Added $($user.DisplayName) to $groupName"
        }
    }

    # STAFF
    elseif ($user.EmployeeType -eq "Staff") {

        $department = $user.Department
        $groupName = "GRP-$department"

        $group = Get-MgGroup -Filter "displayName eq '$groupName'"

        if ($group) {
            New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
            Write-Host "Added $($user.DisplayName) to $groupName"
        }

        # Add to All Staff group
        $allStaffGroup = Get-MgGroup -Filter "displayName eq 'GRP-Staff-All'"
        if ($allStaffGroup) {
            New-MgGroupMember -GroupId $allStaffGroup.Id -DirectoryObjectId $user.Id
        }
    }
}
