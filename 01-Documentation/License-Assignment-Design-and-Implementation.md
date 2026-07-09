# Task 9 - License Assignment: Design and Implementation

## Overview

This document covers the design decisions and implementation details for Microsoft 365 license assignment in the CloudSchool tenant. Licenses are assigned at the group level using the Microsoft Graph PowerShell SDK. Since no licenses are available in the CloudSchool tenant, the script runs in WhatIf simulation mode — demonstrating what would happen in a real environment without making actual changes.

---

## Background

### What is License Assignment?

In Microsoft 365, a license grants a user access to Microsoft services such as Teams, SharePoint, Exchange, and Office apps. Without a license, a user can exist in Entra ID but cannot use any M365 services.

Licenses are a Microsoft 365 / Entra ID concept — they are not managed through the Azure Portal or the Az PowerShell module. They must be assigned via the Microsoft 365 Admin Center or Microsoft Graph API.

### Two Methods of License Assignment

**Direct Assignment** — A license is assigned directly to an individual user. Simple to understand but does not scale. Every new user requires a manual action, and every departure requires manual removal.

**Group-Based Licensing** — A license is assigned to a group. Every member of that group automatically receives the license. When a user joins the group, they get the license. When they leave, it is revoked automatically. This is the recommended enterprise pattern and requires Entra ID P1 minimum.

CloudSchool uses group-based licensing for all assignments.

---

## Design Decisions

### Why Group-Based Licensing?

With 500 students and 55 staff, direct assignment would mean 555 individual license operations. More importantly, every time a student enrolls or a staff member joins, someone would need to manually assign a license. Group-based licensing eliminates this entirely — membership in the right group is all that is needed.

### Why Dedicated License Groups?

Two purpose-built service groups exist specifically for licensing:

- `GRP-M365-License-Students` — students targeted for M365 licensing
- `GRP-M365-License-Staff` — staff targeted for M365 licensing

The decision to use dedicated groups rather than organizational groups (like grade or department groups) is intentional. It keeps licensing concerns separate from organizational structure. If the licensing policy changes — for example, only certain grades get licensed — the organizational groups remain untouched. Only membership in the license group needs to change.

### Why Education Licenses?

CloudSchool is modelled as a school environment, so Education SKUs are the realistic choice:

- Students receive **Office 365 A1 for Students** — a free tier that includes web-based Office apps, Teams, SharePoint, and OneDrive.
- Staff receive **Microsoft 365 A3 for Faculty** — a paid tier that includes full desktop Office apps, advanced security, Intune device management, and more.

The PowerShell skills used to assign these licenses are identical to corporate SKUs (E3, E5). Only the SKU name differs.

### Why WhatIf Mode?

No licenses have been purchased in the CloudSchool tenant. Education SKUs also require Microsoft to verify the tenant as an educational institution, which has not been done. Rather than skip the task, the script is built to run in simulation mode using the `-WhatIf` switch. The full script logic executes — group resolution, SKU lookup, error handling — but the actual Graph API assignment call is skipped.

---

## License Assignments

| Group | License | SkuPartNumber | SkuId (GUID) |
|---|---|---|---|
| GRP-M365-License-Students | Office 365 A1 for Students | STANDARDWOFFPACK_STUDENT | 314c4481-f395-4525-be8b-2ec4bb1e9d91 |
| GRP-M365-License-Staff | Microsoft 365 A3 for Faculty | M365EDU_A3_FACULTY | 4b590615-0888-425a-a965-b3bf7789848d |

SKU GUIDs were sourced from the official Microsoft Learn licensing reference page (last updated March 17, 2025) and verified against the Microsoft Teams Education SKU reference page.

---

## Implementation

### Files

| File | Purpose |
|---|---|
| `02-Scripts/15-assign-licenses.ps1` | Main assignment script |
| `03-CSV-Templates/license-assignments.csv` | License assignment definitions |
| `05-Outputs/license-assignment-results.csv` | Execution results (gitignored) |

### Prerequisites

- Microsoft Graph PowerShell SDK installed
- Global Admin or License Admin role in the Entra ID tenant
- Graph scopes: `Organization.Read.All`, `Group.ReadWrite.All`, `Directory.ReadWrite.All`

### CSV Structure

The CSV drives all assignment logic. Each row represents one group-to-license mapping:

| Column | Purpose |
|---|---|
| GroupName | Display name of the target group in Entra ID |
| GroupDescription | Human-readable description for logging |
| SkuPartNumber | String ID used to look up the SKU in the tenant |
| SkuFriendlyName | Readable name used in log output |
| SkuId | Hardcoded GUID fallback when SKU is not found in tenant |
| TargetUserType | Student or Faculty — for documentation clarity |
| Notes | What the license provides |

### Script Logic

1. Import license assignments from CSV
2. Connect to Microsoft Graph with required scopes
3. Fetch all tenant SKUs once before the loop and store in `$TenantSkus`
4. For each row in CSV:
   - Resolve the group ObjectId using a server-side filter (`Get-MgGroup -Filter`)
   - Look up the SKU from `$TenantSkus` by SkuPartNumber
   - If SKU not found in tenant: log a warning and fall back to the hardcoded SkuId from CSV
   - If `-WhatIf` switch is present: print what would happen and skip the assignment
   - If `-WhatIf` is not present: call `Set-MgGroupLicense` to assign the license
   - Collect result into output array
5. Export results to `05-Outputs/`
6. Print summary to console
7. Disconnect from Microsoft Graph

### Key Implementation Notes

**SKU resolution is done once before the loop** — `Get-MgSubscribedSku` is called once and stored in `$TenantSkus`. Inside the loop, `Where-Object` filters the in-memory collection rather than hitting the Graph API on every iteration. This is the correct pattern at scale.

**Group resolution uses a server-side filter** — `Get-MgGroup -Filter "displayName eq '$GroupName'"` sends the filter to Graph and returns only the matching group. The alternative — fetching all groups and filtering locally — would be expensive in a large tenant with thousands of groups.

**`-ErrorAction Stop` is required on `Set-MgGroupLicense`** — By default, Graph cmdlets throw non-terminating errors that bypass the `catch` block. Adding `-ErrorAction Stop` converts them to terminating errors so `catch` can handle them correctly.

**`Set-MgGroupLicense` requires both `-AddLicenses` and `-RemoveLicenses`** — The cmdlet is designed to handle both adding and removing licenses in a single call. When only adding, `-RemoveLicenses @()` must be passed explicitly as an empty array to satisfy the parameter requirement.

**`-WhatIf` is a custom switch parameter** — It is defined in the `param()` block and checked manually with `if ($WhatIf)`. This is different from PowerShell's built-in WhatIf mechanism (`SupportsShouldProcess`). The approach is intentional — it gives full control over exactly what is simulated and what is logged.

---

## Simulation Output

The script was executed with `-WhatIf` on 2026-06-27. Both groups were resolved successfully. SKUs were not found in the tenant as expected, and the hardcoded GUIDs from CSV were used as fallback.

```
[INFO] Processing: GRP-M365-License-Students -> Office 365 A1 for Students
[INFO] Group resolved: be979988-28bd-4f8c-9b1f-010ac7b48fef
[WARN] SKU 'STANDARDWOFFPACK_STUDENT' not found in tenant. Using hardcoded SkuId from CSV for WhatIf simulation.
[WHATIF] Would assign license 'Office 365 A1 for Students' (SkuId: 314c4481-f395-4525-be8b-2ec4bb1e9d91) to group 'GRP-M365-License-Students' (ObjectId: be979988-28bd-4f8c-9b1f-010ac7b48fef)

[INFO] Processing: GRP-M365-License-Staff -> Microsoft 365 A3 for Faculty
[INFO] Group resolved: 1cfde0e5-5cf6-4ede-9a53-0934bbffc150
[WARN] SKU 'M365EDU_A3_FACULTY' not found in tenant. Using hardcoded SkuId from CSV for WhatIf simulation.
[WHATIF] Would assign license 'Microsoft 365 A3 for Faculty' (SkuId: 4b590615-0888-425a-a965-b3bf7789848d) to group 'GRP-M365-License-Staff' (ObjectId: 1cfde0e5-5cf6-4ede-9a53-0934bbffc150)

========================================
  LICENSE ASSIGNMENT SUMMARY
========================================
  Total Processed : 2
  WhatIf Mode     : True
  [WhatIf - Would assign] GRP-M365-License-Students -> Office 365 A1 for Students
  [WhatIf - Would assign] GRP-M365-License-Staff -> Microsoft 365 A3 for Faculty
========================================
```

---

## References

- [Microsoft Learn - Product names and service plan identifiers for licensing](https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference)
- [Microsoft Learn - Education SKU reference for Microsoft Teams](https://learn.microsoft.com/en-us/microsoftteams/sku-reference-edu)
- [Microsoft Learn - Group-based licensing in Entra ID](https://learn.microsoft.com/en-us/entra/identity/users/licensing-group-advanced)
- [Microsoft Graph API - Set group license](https://learn.microsoft.com/en-us/graph/api/group-assignlicense)
