# -------- Variables --------
$csvPath = "G:\CloudSchool-Cloud-Administration-Project\03-CSV-Templates\new_staff_additions.csv"
$headers = @{
    Authorization  = "Bearer $($msalToken.AccessToken)"
    "Content-Type" = "application/json"
}

$staffList = Import-Csv $csvPath

# -------- Loop through CSV --------
foreach ($staff in $staffList) {

    $upn = $staff.UPN.Trim()
    $mailNickname = $upn.Split("@")[0]

    # ---- Check if user exists ----
    try {
        Invoke-RestMethod `
            -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/users/$upn" `
            -Headers $headers `
            -ErrorAction Stop

        Write-Host "SKIPPED - User already exists: $upn" -ForegroundColor Yellow
        continue
    }
    catch {
        if ($_.ErrorDetails.Message -notmatch "Request_ResourceNotFound") {
            Write-Host "ERROR checking user $upn" -ForegroundColor Red
            continue
        }
    }

    # ---- Create user ----
    $body = @{
        accountEnabled    = $true
        displayName       = $staff.DisplayName.Trim()
        mailNickname      = $mailNickname
        userPrincipalName = $upn
        department        = $staff.Department.Trim()
        employeeType      = $staff.EmployeeType.Trim()
        usageLocation     = "AE"
        passwordProfile   = @{
            password = "P@ssw0rd123!"
            forceChangePasswordNextSignIn = $true
        }
    } | ConvertTo-Json -Depth 5

    try {
        Invoke-RestMethod `
            -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/users" `
            -Headers $headers `
            -Body $body `
            -ErrorAction Stop

        Write-Host "CREATED - $($staff.DisplayName) ($upn)" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR creating user $upn" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
    }
}

Write-Host "Script complete." -ForegroundColor Cyan