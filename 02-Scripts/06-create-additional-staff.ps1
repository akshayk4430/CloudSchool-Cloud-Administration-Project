Connect-MgGraph -TenantId "22758c9c-f30c-404d-ba40-c5b01af9cab6" -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All" -UseDeviceAuthentication

$csvUrl = "https://raw.githubusercontent.com/akshayk4430/CloudSchool-Cloud-Administration-Project/refs/heads/main/03-CSV-Templates/new_staff_additions.csv"
$staffList = Invoke-RestMethod -Uri $csvUrl | ConvertFrom-Csv

foreach ($staff in $staffList) {
    $upn = $staff.UPN.Trim()
    $existing = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Host "SKIP - User already exists: $upn" -ForegroundColor Yellow
        continue
    }

    try {
        New-MgUser `
            -DisplayName $staff.DisplayName.Trim() `
            -UserPrincipalName $upn `
            -MailNickname ($upn.Split("@")[0]) `
            -Department $staff.Department.Trim() `
            -EmployeeType $staff.EmployeeType.Trim() `
            -AccountEnabled `
            -PasswordProfile @{ Password = "P@ssw0rd123!"; ForceChangePasswordNextSignIn = $true }

        Write-Host "CREATED - $($staff.DisplayName) ($upn)" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR - $upn : $_" -ForegroundColor Red
    }
}

Write-Host "Script 06 complete." -ForegroundColor Cyan
