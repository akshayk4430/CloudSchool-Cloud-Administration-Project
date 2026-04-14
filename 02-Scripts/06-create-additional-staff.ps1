# ============================================================
# Script 06 — Create Additional Staff Users
# CloudSchool Cloud Administration Project
# ============================================================
# Pulls new_staff_additions.csv from GitHub and creates users
# Default password: P@ssw0rd123! (force change on next sign-in)
# ============================================================

# --- Connect to Microsoft Graph ---
Connect-MgGraph -TenantId "22758c9c-f30c-404d-ba40-c5b01af9cab6" -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

# --- Load CSV from GitHub ---
$csvUrl = "https://raw.githubusercontent.com/akshayk4430/CloudSchool-Cloud-Administration-Project/refs/heads/main/03-CSV-Templates/new_staff_additions.csv"
$staffList = Invoke-RestMethod -Uri $csvUrl | ConvertFrom-Csv

# --- Default Password ---
$passwordProfile = @{
    Password                      = "P@ssw0rd123!"
    ForceChangePasswordNextSignIn = $true
}

# --- Create Users ---
foreach ($staff in $staffList) {
    $upn = $staff.UPN.Trim()

    # Check if user already exists
    $existing = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Host "SKIP — User already exists: $upn" -ForegroundColor Yellow
        continue
    }

    try {
        New-MgUser `
            -DisplayName $staff.DisplayName.Trim() `
            -UserPrincipalName $upn `
            -MailNickname ($upn.Split("@")[0]) `
            -Department $staff.Department.Trim() `
            -EmployeeType $staff.EmployeeType.Trim() `
            -AccountEnabled $true `
            -PasswordProfile $passwordProfile

        Write-Host "CREATED — $($staff.DisplayName) ($upn)" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR — $upn : $_" -ForegroundColor Red
    }
}

Write-Host "`nScript 06 complete." -ForegroundColor Cyan
