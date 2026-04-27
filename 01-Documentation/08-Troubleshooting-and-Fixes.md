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


Issue: Microsoft Graph PowerShell SDK Breaking (v2.36.1)

Problem:

Microsoft Graph PowerShell SDK version 2.36.1 was unstable in this environment
Frequent failures while importing modules and running Graph commands
Errors included:
Module load failures (Microsoft.Graph.Authentication.dll not found)
Connect-MgGraph not recognized or failing
Inconsistent behavior across sessions

Root Cause:

Version mismatch and broken dependencies in SDK v2.36.1
Submodules not properly aligned or installed
Known instability with newer Graph SDK releases in some environments (especially PowerShell 7)

Fix Implemented:

Fully removed existing Graph modules

Installed stable version:

Microsoft Graph PowerShell SDK version 2.24.0

Commands Used:

Get-InstalledModule Microsoft.Graph* | Uninstall-Module -AllVersions -Force

Install-Module Microsoft.Graph -RequiredVersion 2.24.0 -Scope CurrentUser -Force -AllowClobber

Result:

Module imports successful
Connect-MgGraph working consistently
All provisioning scripts executed without SDK-related failures

Recommendation:

Avoid latest SDK versions without validation
Use a known stable version (2.24.0) for production scripts
Lock module version in documentation and scripts to prevent breaking changes
