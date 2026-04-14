# ============================================================
# Script 07 — Update Staff Extension Attributes
# CloudSchool Cloud Administration Project
# ============================================================
# Pulls staff_attributes.csv from GitHub and updates
# extensionAttribute1 (Position) and extensionAttribute2 (AssignedTo)
# for all 54 staff users
# ============================================================

# --- Connect to Microsoft Graph ---
Connect-MgGraph -TenantId "22758c9c-f30c-404d-ba40-c5b01af9cab6" -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

# --- Load CSV from GitHub ---
$csvUrl = "https://raw.githubusercontent.com/akshayk4430/CloudSchool-Cloud-Administration-Project/refs/heads/main/03-CSV-Templates/staff_attributes.csv"
$attributeList = Invoke-RestMethod -Uri $csvUrl | ConvertFrom-Csv

# --- Update Attributes ---
foreach ($entry in $attributeList) {
    $upn = $entry.UPN.Trim()
    $attr1 = $entry.ExtensionAttribute1.Trim()
    $attr2 = $entry.ExtensionAttribute2.Trim()

    # Check if user exists
    $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -Property "Id,UserPrincipalName,OnPremisesExtensionAttributes" -ErrorAction SilentlyContinue

    if (-not $user) {
        Write-Host "NOT FOUND — $upn" -ForegroundColor Red
        continue
    }

    try {
        Update-MgUser -UserId $user.Id -OnPremisesExtensionAttributes @{
            ExtensionAttribute1 = $attr1
            ExtensionAttribute2 = $attr2
        }

        Write-Host "UPDATED — $upn | Attr1: $attr1 | Attr2: $attr2" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR — $upn : $_" -ForegroundColor Red
    }
}

Write-Host "`nScript 07 complete." -ForegroundColor Cyan
