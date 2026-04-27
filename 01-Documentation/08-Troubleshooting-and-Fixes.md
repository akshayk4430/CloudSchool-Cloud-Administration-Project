```markdown
# Troubleshooting and Fixes

## 📌 Purpose
This document records issues faced during the project and how they were resolved.

---

## ⚠️ Issue 1: Blank CSV Export

### Problem
While exporting users from groups, the CSV file was generated but contained no data.

### Possible Cause
- GroupId was not correctly retrieved
- Script failed to fetch group members

### Error Observed

### Fix / Approach
- Verified group name and existence
- Ensured correct retrieval of GroupId using:
```powershell
Get-MgGroup -Filter "displayName eq 'GROUP_NAME'"


##⚠️ Issue 2: 403 Forbidden When Creating Administrative Units

### What Happened
When running `05-create-administrative-units.ps1`, the script failed with a 
403 Forbidden error when attempting to create or modify Administrative Units.

### Root Cause
The Graph session was connected without specifying the required scope for 
Administrative Units. General scopes like `User.ReadWrite.All`, 
`Group.ReadWrite.All`, or `Directory.ReadWrite.All` are not sufficient 
for AU operations.

### Error Symptom

### Fix
Disconnect the current session and reconnect with the correct scope:

```powershell
Disconnect-MgGraph

Connect-MgGraph -TenantId "22758c9c-f30c-404d-ba40-c5b01af9cab6" -Scopes "AdministrativeUnit.ReadWrite.All"
```

Then re-run the script.

### Lesson
Every script that touches AUs must use `AdministrativeUnit.ReadWrite.All` 
explicitly. Do not assume that broad directory scopes cover AU operations — 
they do not. Always check the required scope before running a new category 
of script.

### Affected Script
`02-Scripts/05-create-administrative-units.ps1`


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
