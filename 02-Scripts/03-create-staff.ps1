# 03-create-staff.ps1

$staffs = Import-Csv ".\data\staff.csv"

foreach ($staff in $staffs) {

    $passwordProfile = @{
        Password = "P@ssw0rd123!"
        ForceChangePasswordNextSignIn = $true
    }

    New-MgUser -DisplayName $staff.DisplayName `
        -UserPrincipalName $staff.UPN `
        -AccountEnabled $true `
        -MailNickname ($staff.UPN.Split("@")[0]) `
        -Department $staff.Department `
        -PasswordProfile $passwordProfile `
        -AdditionalProperties @{
            "employeeType" = "Staff"
        }

    Write-Host "Created staff: $($staff.DisplayName)"
}
