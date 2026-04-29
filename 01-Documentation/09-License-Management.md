````markdown
# License Management

## 1. Purpose

Licenses in Microsoft 365 are required to enable services such as Exchange Online, Teams, and SharePoint.  
Without a license, users remain as identity objects and cannot access these services.

---

## 2. Licensing Model

The environment is designed using **group-based licensing**.

Groups used:

- GRP-M365-License-Students
- GRP-M365-License-Staff

Users are assigned to these groups based on their role.

---

## 3. License SKU

License used:

- Microsoft 365 Business Premium (SPB)

---

## 4. License Assignment Method

Licenses are assigned at the group level using Microsoft Graph PowerShell.

Example:

```powershell
$sku = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "SPB"}

Set-MgGroupLicense -GroupId "<GROUP_ID>" `
-AddLicenses @{SkuId = $sku.SkuId} `
-RemoveLicenses @()
````

---

## 5. Service Plan Control

Each license contains multiple services (service plans).

Examples:

* Exchange Online
* Microsoft Teams
* SharePoint Online

Specific services can be enabled or disabled depending on requirements.

---

## 6. Limitation

License assignment was not executed in this environment due to trial limitations.

* Available licenses: 1
* Required licenses: 555+

Because of this, license assignment is designed but not implemented.

---

## 7. Validation Approach

If licenses were available, validation would include:

* Verify license assignment to users
* Confirm mailbox creation in Exchange Online
* Confirm Teams access
* Confirm OneDrive provisioning

---

## 8. Summary

The licensing model is fully designed using group-based assignment.
Execution is limited due to licensing constraints, but the architecture is production-ready.

```

---
