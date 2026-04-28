# Troubleshooting and Fixes

This document captures real issues encountered during the CloudSchool project along with root cause analysis and resolutions.

Format used:
- Symptoms → What was observed
- Cause → Why it happened
- Fix → What was done
- Result → Outcome after fix

  
## ⚠️ Issue 1: Blank CSV Export

### Symptoms
- CSV file generated but contains no data

### Cause
- GroupId was not correctly retrieved
- Script failed to fetch group members

### Fix
- Verified group name and existence
- Retrieved GroupId using:

```powershell
Get-MgGroup -Filter "displayName eq 'GROUP_NAME'"

### Result
- CSV export populated correctly with group members

## ⚠️ Issue 2: 403 Forbidden When Creating Administrative Units

### Symptoms
- 403 Forbidden error when creating Administrative Units
- `Authorization_RequestDenied` returned from Microsoft Graph

### Cause
- Missing required permission: AdministrativeUnit.ReadWrite.All
- Existing Graph connection did not include required scope

### Fix
- Disconnected existing session:
  Disconnect-MgGraph

- Reconnected with required scope:
  Connect-MgGraph -TenantId "22758c9c-f30c-404d-ba40-c5b01af9cab6" -Scopes "AdministrativeUnit.ReadWrite.All"

- Re-ran the script

### Result
- Administrative Units created successfully
- No further permission errors


Issue: Microsoft Graph SDK Module Failure (v2.36.1)

Symptoms:

Connect-MgGraph command not recognized or failing
Module import errors for Microsoft Graph
Missing or invalid Microsoft.Graph.Authentication.dll
Inconsistent behavior across sessions

Cause:

Unstable or broken dependencies in Microsoft Graph PowerShell SDK version 2.36.1
Version mismatch between core module and submodules

Fix:

Removed all existing Microsoft Graph modules
Installed stable version 2.24.0

Commands Used:

Get-InstalledModule Microsoft.Graph* | Uninstall-Module -AllVersions -Force

Install-Module Microsoft.Graph -RequiredVersion 2.24.0 -Scope CurrentUser -Force -AllowClobber

Result:

Module imports successful
Connect-MgGraph working correctly
All scripts executed without SDK-related issues
