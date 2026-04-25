<#
.SYNOPSIS
Validates and updates student user accounts from CSV against Microsoft Entra ID.

.DESCRIPTION
Reads student records from students.csv, compares selected identity attributes,
updates mismatched users, skips matching users, and logs results to CSV.

.NOTES
Safe to re-run. Idempotent.
#>

param (
       [string]$CsvPath = ".\03-CSV-Templates\students.csv",
	   [string]$OutputPath = ".\05-Outputs\students-results.csv"
)
$students = Import-Csv $CsvPath -Delimiter ','

$results = @()


foreach ($student in $students) {
	
	$user = Get-MgUser `
		-Filter "userPrincipalName eq '$($student.userPrincipalName)'" `
		-Property "Id,DisplayName,GivenName,Surname,Department,EmployeeType,UsageLocation,OnPremisesExtensionAttributes" `
# 		-ErrorAction SilentlyContinue

	if (-not $user) {
            $passwordProfile = @{
                Password = "CloudSchool@12345"
                ForceChangePasswordNextSignIn = $true
            }

            New-MgUser `
                -AccountEnabled `
                -DisplayName $student.DisplayName `
                -GivenName $student.GivenName `
                -Surname $student.Surname `
                -UserPrincipalName $student.UserPrincipalName `
                -MailNickname $student.MailNickname `
                -Department $student.Department `
                -EmployeeType $student.EmployeeType `
                -UsageLocation $student.UsageLocation `
                -PasswordProfile $passwordProfile `
                -OnPremisesExtensionAttributes @{
                    ExtensionAttribute1 = $student.ExtensionAttribute1
                    ExtensionAttribute2 = $student.ExtensionAttribute2
                } `
                -ErrorAction Stop

            $action = "Create"
            $status = "Success"
            $notes = "User created"
	}
	else {
    $changes = @()

    if ($user.DisplayName -ne $student.DisplayName) {
        $changes += "DisplayName"
    }

    if ($user.GivenName -ne $student.GivenName) {
        $changes += "GivenName"
    }

    if ($user.Surname -ne $student.Surname) {
        $changes += "Surname"
    }

    if ($user.Department -ne $student.Department) {
        $changes += "Department"
    }

    if ($user.EmployeeType -ne $student.EmployeeType) {
        $changes += "EmployeeType"
    }

    if ($user.UsageLocation -ne $student.UsageLocation) {
        $changes += "UsageLocation"
    }

    $ext1 = $user.OnPremisesExtensionAttributes.ExtensionAttribute1
    $ext2 = $user.OnPremisesExtensionAttributes.ExtensionAttribute2

    if ($ext1 -ne $student.ExtensionAttribute1) {
        $changes += "ExtensionAttribute1"
    }

    if ($ext2 -ne $student.ExtensionAttribute2) {
        $changes += "ExtensionAttribute2"
    }

    if ($changes.Count -gt 0) {

        $params = @{}

        if ($changes -contains "DisplayName") {
            $params.DisplayName = $student.DisplayName
        }

        if ($changes -contains "GivenName") {
            $params.GivenName = $student.GivenName
        }

        if ($changes -contains "Surname") {
            $params.Surname = $student.Surname
        }

        if ($changes -contains "Department") {
            $params.Department = $student.Department
        }

        if ($changes -contains "EmployeeType") {
            $params.EmployeeType = $student.EmployeeType
        }

        if ($changes -contains "UsageLocation") {
            $params.UsageLocation = $student.UsageLocation
        }

        if ($changes -contains "ExtensionAttribute1" -or $changes -contains "ExtensionAttribute2") {
            $params.OnPremisesExtensionAttributes = @{
                ExtensionAttribute1 = $student.ExtensionAttribute1
                ExtensionAttribute2 = $student.ExtensionAttribute2
            }
        }

        Write-Host "Updating $($student.UserPrincipalName)"
        $params | Format-List

       	try {
    		Update-MgUser -UserId $user.Id @params
    		$action = "Update"
    		$notes = "Updated: " + ($changes -join ", ")
    		$status = "Success"
	}
	catch {
    		$action = "Update"
    		$notes = $_.Exception.Message
    		$status = "Failed"
	}

        $action = "Update"
        $notes = "Updated: " + ($changes -join ", ")
    }
    else {
        $action = "Skip"
		$status = "Success"
        $notes = "Already Correct"
    }
}

	$results +=[pscustomobject]@{
		UserPrincipalName = $student.UserPrincipalName
		DisplayName	  = $student.DisplayName
		Action		  = $action
		Status		  = $status
		Notes		  = $notes
	}
}

$results | Export-Csv $OutputPath	-NoTypeInformation
Write-Host "Student provisioning completed." -ForegroundColor Green
Write-Host "Results exported to $OutputPath" -ForegroundColor Green