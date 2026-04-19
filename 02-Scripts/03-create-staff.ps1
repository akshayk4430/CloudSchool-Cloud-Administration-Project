# ========================================
# CloudSchool - Staff Provisioning
# Create / Update / Skip staff users
# Source: .\03-CSV-Templates\staff-final.csv
# ========================================

$CsvPath    = ".\03-CSV-Templates\staff-final.csv"
$OutputPath = ".\05-Outputs\staff-provisioning-results.csv"

# Ensure output folder exists
$outputFolder = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputFolder)) 
{
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
}

# Import CSV
$staffUsers = Import-Csv $CsvPath

# Result collection
$results = @()

foreach ($staff in $staffUsers) 
{
    $result = [PSCustomObject]@{
        UserPrincipalName = $staff.UserPrincipalName
        DisplayName       = $staff.DisplayName
        Action            = ""
        Status            = ""
        Notes             = ""
    }

    try 
    {
        $existingUser = Get-MgUser -Filter "userPrincipalName eq '$($staff.UserPrincipalName)'" -Property "Id,DisplayName,GivenName,Surname,Department,EmployeeType,UsageLocation,OnPremisesExtensionAttributes"

if (-not $existingUser) 
{
    try
    {
        $passwordProfile = @{
            Password = 'CloudSchool@123!'
            ForceChangePasswordNextSignIn = $true
        }

New-MgUser `
    -AccountEnabled `
    -DisplayName $staff.DisplayName `
    -UserPrincipalName $staff.UserPrincipalName `
    -MailNickname $staff.MailNickname `
    -GivenName $staff.GivenName `
    -Surname $staff.Surname `
    -Department $staff.Department `
    -UsageLocation $staff.UsageLocation `
    -EmployeeType $staff.EmployeeType `
    -PasswordProfile $passwordProfile | Out-Null

        $result.Action = "Create"
        $result.Status = "Success"
        $result.Notes  = "User created successfully"
    }
    catch
    {
        $result.Action = "Create"
        $result.Status = "Failed"
        $result.Notes  = $_.Exception.Message
    }
}
        else 
        {
            $changes = @()
            $updateParams = @{}

            if ($existingUser.DisplayName -ne $staff.DisplayName) {
                $changes += "DisplayName"
                $updateParams["DisplayName"] = $staff.DisplayName
            }

            if ($existingUser.GivenName -ne $staff.GivenName) {
                $changes += "GivenName"
                $updateParams["GivenName"] = $staff.GivenName
            }

            if ($existingUser.Surname -ne $staff.Surname) {
                $changes += "Surname"
                $updateParams["Surname"] = $staff.Surname
            }

            if ($existingUser.Department -ne $staff.Department) {
                $changes += "Department"
                $updateParams["Department"] = $staff.Department
            }

            if ($existingUser.EmployeeType -ne $staff.EmployeeType) {
                $changes += "EmployeeType"
                $updateParams["EmployeeType"] = $staff.EmployeeType
            }

            if ($existingUser.UsageLocation -ne $staff.UsageLocation) {
                $changes += "UsageLocation"
                $updateParams["UsageLocation"] = $staff.UsageLocation
            }
			$extensionAttributesChanged = $false
			$extensionAttributes = @{}

			if ($existingUser.OnPremisesExtensionAttributes.ExtensionAttribute1 -ne $staff.ExtensionAttribute1) {
			$changes += "ExtensionAttribute1"
			$extensionAttributes["extensionAttribute1"] = $staff.ExtensionAttribute1
			$extensionAttributesChanged = $true
			}

			if ($existingUser.OnPremisesExtensionAttributes.ExtensionAttribute2 -ne $staff.ExtensionAttribute2) {
			$changes += "ExtensionAttribute2"
			$extensionAttributes["extensionAttribute2"] = $staff.ExtensionAttribute2
			$extensionAttributesChanged = $true
}

if ($extensionAttributesChanged) {
    $updateParams["onPremisesExtensionAttributes"] = $extensionAttributes
}

            if ($changes.Count -eq 0) 
            {
                $result.Action = "Skip"
                $result.Status = "Success"
                $result.Notes  = "Already correct"
            }
            else 
            {
                try 
                {
                    Update-MgUser -UserId $existingUser.Id @updateParams

                    $result.Action = "Update"
                    $result.Status = "Success"
                    $result.Notes  = "Updated: $($changes -join ', ')"
                }
                catch 
                {
                    $result.Action = "Update"
                    $result.Status = "Failed"
                    $result.Notes  = $_.Exception.Message
                }
            }
        }
    } 
    catch 
    {
        $result.Action = "Error"
        $result.Status = "Failed"
        $result.Notes  = $_.Exception.Message
    }

    $results += $result
}

# ✅ OUTSIDE loop (critical fix)
$results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Staff provisioning complete. Results exported to: $OutputPath"