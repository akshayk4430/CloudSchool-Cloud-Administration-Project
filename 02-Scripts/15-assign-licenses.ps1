
# =============================================================================
# Script  : 15-assign-licenses.ps1
# Project : CloudSchool Cloud Administration
# Task    : Task 9 - License Assignment (Group-Based)
# Author  : AkshayKattoth
# Date    : 2026-06-27
# 
# Description:
#   Assigns Microsoft 365 Education licenses to groups using group-based
#   licensing via Microsoft Graph API. Targets GRP-Students-All and
#   GRP-Staff-All. Runs in WhatIf simulation mode as no licenses are
#   available in the tenant.
#
# Prerequisites:
#   - Microsoft.Graph PowerShell SDK installed
#   - Global Admin or License Admin role in Entra ID
#   - license-assignments.csv in 03-CSV-Templates/
#
# Graph Scopes Required:
#   - Organization.Read.All
#   - Group.ReadWrite.All
#   - Directory.ReadWrite.All
#
# Usage:
#   .\15-assign-licenses.ps1
# =============================================================================

# -----------------------------------------------------------------------------
# Parameters
# -----------------------------------------------------------------------------
param(
	[switch]$WhatIf
)
$CsvPath 	= "$PSScriptRoot\..\03-CSV-Templates\license-assignments.csv"
$OutputPath	= "$PSScriptRoot\..\05-Outputs\license-assignment-results.csv"
$Results 	= @()

# -----------------------------------------------------------------------------
# Import CSV
# -----------------------------------------------------------------------------
Write-Host "`n[INFO] Importing license assignments from CSV..." -ForeGroundColor Cyan

if(-not(Test-Path $CsvPath)){
	Write-Host "[ERROR] CSV not found at: $CsvPath" -ForeGroundColor Red
	exit 1
}
$Assignments	= Import-Csv -Path $CsvPath
Write-Host "[INFO] Loaded $($Assignments.Count) assignment(s) from CSV." -ForeGroundColor Cyan

# -----------------------------------------------------------------------------
# Connect to Microsoft Graph
# -----------------------------------------------------------------------------

Write-Host "`n[INFO] Connecting to Microsoft Graph..." -ForeGroundColor Cyan

Connect-MgGraph -Scopes "Organization.Read.All", "Group.ReadWrite.All", "Directory.ReadWrite.All" `
				-TenantId "401bd5c7-e8b2-4bee-83f6-abf0bad3b953" `
				-NoWelcome

Write-Host "[INFO] Connected to Microsoft Graph." -ForeGroundColor Green

# -----------------------------------------------------------------------------
# Assign Licenses
# -----------------------------------------------------------------------------

# --- Resolve all SKUs once before the loop ---
$TenantSkus = Get-MgSubscribedSku

Write-Host "`n[INFO] Starting license assignment loop..." -ForegroundColor Cyan
foreach($Row in $Assignments){
	$GroupName 			= $Row.GroupName
	$SkuPartNumber		= $Row.SkuPartNumber
	$SkuFriendlyName	= $Row.SkuFriendlyName
	$SkuId				= $Row.SkuId
	
  Write-Host "`n[INFO] Processing: $GroupName -> $SkuFriendlyName" -ForegroundColor Cyan
  
   # --- Resolve Group ObjectId ---
   $Group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue
   
   if(-not $Group){
	    Write-Host "[ERROR] Group not found: $GroupName" -ForegroundColor Red
		$Results += [PSCustomObject]@{
			GroupName 		= $GroupName
			SkuFriendlyName	= $SkuFriendlyName
			SkuPartNumber	= $SkuPartNumber
			Status			= "Failed - Group not found"
			WhatIf			= $WhatIf.IsPresent
			Timestamp		= (Get-Date -Format "yyyy-mm-dd HH:mm:ss")
		}
		continue
   }
   Write-Host "[INFO] Group resolved: $($Group.Id)" -ForegroundColor Gray
   
   # --- Resolve SKU from tenant (expected to fail - no licenses purchased) ---
   $Sku = $TenantSkus | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber }
   
   if(-not $Sku){
	   Write-Host "[WARN] SKU '$SkuPartNumber' not found in tenant. Using hardcoded SkuId from CSV for WhatIf simulation." -ForegroundColor Yellow
	   $ResolvedSkuId 	= $SkuId
	   $SkuSource		= "Csv-Hardcoded"
   }
   else{
	   $ResolvedSkuId	= $Sku.SkuId
	   $SkuSource		= "Tenant-Resolved"
	   Write-Host "[INFO] SKU resolved from tenant: $ResolvedSkuId" -ForegroundColor Gray
   }
   
   # --- WhatIf Simulation ---
   if($WhatIf){
	   Write-Host "[WHATIF] Would assign license '$SkuFriendlyName' (SkuId: $ResolvedSkuId) to group '$GroupName' (ObjectId: $($Group.Id))" -ForegroundColor Magenta
       $Status = "WhatIf - Would assign"
   }
   else{
	   # --- Actual Assignment ---
	   try{
		   Set-MgGroupLicense -GroupId $Group.Id -AddLicenses @{SkuId = $ResolvedSkuId} -RemoveLicenses @() -ErrorAction Stop
		   Write-Host "[SUCCESS] License assigned: $SkuFriendlyName -> $GroupName" -ForegroundColor Green
           $Status = "Success"
	   }
	   catch{
		   Write-Host "[ERROR] Failed to assign license: $_" -ForegroundColor Red
           $Status = "Failed - $($_.Exception.Message)"
	   }
   }
   
   # --- Collect Result ---
    $Results += [PSCustomObject]@{
        GroupName        = $GroupName
        SkuFriendlyName  = $SkuFriendlyName
        SkuPartNumber    = $SkuPartNumber
        ResolvedSkuId    = $ResolvedSkuId
        SkuSource        = $SkuSource
        GroupObjectId    = $Group.Id
        Status           = $Status
        WhatIf           = $WhatIf.IsPresent
        Timestamp        = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
	}
}

# -----------------------------------------------------------------------------
# Export Results
# -----------------------------------------------------------------------------
Write-Host "`n[INFO] Exporting results to: $OutputPath" -ForegroundColor Cyan

$Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "[INFO] Export complete." -ForegroundColor Green
# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
Write-Host "`n========================================" -ForegroundColor White
Write-Host "  LICENSE ASSIGNMENT SUMMARY" -ForegroundColor White
Write-Host "========================================" -ForegroundColor White
Write-Host "  Total Processed : $($Results.Count)"
Write-Host "  WhatIf Mode     : $($WhatIf.IsPresent)"

foreach ($R in $Results) {
    $Color = if ($R.Status -like "WhatIf*") { "Magenta" } `
             elseif ($R.Status -eq "Success") { "Green" } `
             else { "Red" }
    Write-Host "  [$($R.Status)] $($R.GroupName) -> $($R.SkuFriendlyName)" -ForegroundColor $Color
}

Write-Host "========================================`n" -ForegroundColor White

# -----------------------------------------------------------------------------
# Disconnect
# -----------------------------------------------------------------------------
Disconnect-MgGraph
Write-Host "[INFO] Disconnected from Microsoft Graph.`n" -ForegroundColor Cyan