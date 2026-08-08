# PowerShell Automation Guide

## Objective

This document explains how PowerShell is used to automate the CloudSchool environment end to end — identity and group management in Microsoft Entra ID via the Microsoft Graph SDK (scripts 01–06, 08–09, 13, 15), and Azure infrastructure via the Az module (scripts 07, 10–12, 14, 16–17).

---

## Why PowerShell?

Managing hundreds of users and dozens of Azure resources manually is not practical.

PowerShell enables:

* Bulk user provisioning
* Automated group creation
* Automated group assignment
* Attribute standardization
* Azure infrastructure provisioning (resource groups, networking, storage)
* Role and policy assignment
* Export and reporting
* Idempotent operations

---

## Authentication

Two separate connections are used depending on which layer a script operates on:

**Microsoft Graph (Entra ID / identity scripts):**
```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All","AdministrativeUnit.ReadWrite.All"
```

**Az module (Azure infrastructure scripts):**
```powershell
Connect-AzAccount -TenantId "401bd5c7-e8b2-4bee-83f6-abf0bad3b953"
```

Scripts state in their own header/comments which connection they require. Licenses (script 15) use Graph, not Az, since licenses are an Entra ID/M365 concept, not an Azure Resource Manager concept.

---

## Automation Architecture

The automation is designed as a pipeline:

```text
CSV → Script → Entra ID / Azure → Validation Output
```

Key principles:

* CSV is the source of truth
* Scripts compare before updating
* Only required changes are applied
* Scripts are safe to re-run

---

## Script Overview

### 01-connect-mggraph.ps1

* Connects to Microsoft Graph
* Required before running any other script

---

### 02-create-students.ps1

* Reads `students.csv`
* Creates new users
* Updates existing users if changes detected
* Skips users already in correct state
* Applies:

  * EmployeeType
  * ExtensionAttribute1 (Grade)
  * ExtensionAttribute2 (Division)

---

### 03-create-staff.ps1

* Reads `staff-final.csv`
* Handles:

  * Create / Update / Skip logic
  * Department assignment
  * Role assignment (ExtensionAttribute1)

---

### 04-Create-Groups.ps1

* Reads `groups-required.csv`
* Creates missing groups
* Skips existing groups
* Idempotent design

Output:

```text
05-Outputs/group-creation-results.csv
```

---

### 05-Assign-Users-To-Groups.ps1

* Assigns users to groups based on attributes

Student logic:

```text
Grade + Division → Student groups  
License + Policy → Service groups  
```

Staff logic:

```text
All staff + Department → Organizational groups  
License + Policy → Service groups  
Role + Department → Role-based groups  
```

Features:

* Caches groups and memberships
* Checks membership before adding
* Prevents duplicate operations
* Logs results

Output:

```text
05-Outputs/group-assignment-results.csv
```

---

### 06-create-administrative-units.ps1

* Creates administrative units
* Assigns users based on attributes
* Used for delegation and RBAC scenarios

---

### 07-create-resource-groups.ps1

* Az module script — first script requiring `Connect-AzAccount`
* Reads `resource-groups.csv`
* Creates the 6 CloudSchool resource groups (Prod/Dev split across Network, Compute, Storage, Monitoring)
* Applies `Environment` and `Project` tags
* Idempotent — checks with `Get-AzResourceGroup` before creating

---

### 08-build-staff-csv.ps1

* Cleans a raw staff export into a standardized `staff.csv`
* First step of the staff source-of-truth chain (see `Staff-Provisioning.md`)

---

### 09-merge-staff-csv.ps1

* Merges `staff.csv` with `staff-attributes.csv`
* Produces `staff-final.csv`, the actual input used by `03-create-staff.ps1`
* Corrections to staff data must go through `staff-attributes.csv`, not `staff-final.csv` directly

---

### 10-connect-AzAccount.ps1

* Connects to Azure using `Connect-AzAccount -TenantId`
* Required before running any other Az module script (07, 11, 12, 14, 16, 17)

---

### 11-create-vnets-and-subnets.ps1

* Reads `vnets.csv`
* Creates `VNet-CloudSchool-Prod` and `VNet-CloudSchool-Dev` with their respective subnets
* Idempotent — checks for existing VNet/subnet before creating

---

### 12-assign-allowed-location-policy.ps1

* Assigns the built-in **Allowed locations** Azure Policy to `RG-Compute-Dev`
* Effect: `Audit`, restricted to `uaenorth`
* Supports `-WhatIf`

---

### 13-role-delegation.ps1

* Creates role-assignable Entra ID groups
* Assigns scoped Helpdesk Administrator role to Administrative Units via those groups
* Never assigns roles directly to individual users

---

### 14-assign-rbac-roles.ps1

* Reads `rbac-assignments.csv`
* Assigns Azure RBAC roles to users/groups at subscription, resource group, or resource scope
* `ScopeType = Resource` uses the full resource ID held in `ScopeName`, validated with `Get-AzResource` before assignment
* Idempotent — checks existing role assignments before creating new ones
* Output filename is timestamped so run history is preserved

---

### 15-assign-licenses.ps1

* Reads `license-assignments.csv`
* Assigns Microsoft 365 Education licenses at the group level (Graph SDK, not Az — licenses are an Entra ID/M365 concept)
* Runs in `-WhatIf` simulation mode since no purchased licenses exist in the tenant
* See `License-Assignment-Design-and-Implementation.md` for full detail

---

### 16-create-storage-account.ps1

* Reads `storage-accounts.csv`
* Two-step create-then-configure pattern (`AllowBlobPublicAccess` only settable via `Set-AzStorageAccount`)
* Applies tags, TLS 1.2 minimum, HTTPS enforcement, HNS setting (creation-time only)
* See `Storage-Account-Design-and-Implementation.md` for full detail

---

### 17-create-blob-containers.ps1

* Reads `blob-containers.csv` and `blob-service-properties.csv`
* Applies blob and container soft delete via `Enable-AzStorageBlobDeleteRetentionPolicy` and `Enable-AzStorageContainerDeleteRetentionPolicy` — note that `Update-AzStorageBlobServiceProperty` does not expose soft delete parameters in Az.Storage 9.6.0
* Creates blob containers using a data-plane context bound to the signed-in Entra identity (`New-AzStorageContext -UseConnectedAccount`), not account keys
* Requires `Storage Blob Data Contributor` on the storage account — control-plane roles such as Owner grant no data-plane access
* Idempotent — checks with `Get-AzStorageContainer` before creating, and normalises a null `PublicAccess` to `Off` to avoid false drift
* See `Blob-Storage-Design-and-Implementation.md` for full detail

---

## Idempotent Design

All scripts follow:

```text
Create / Update / Skip / Failed
```

This ensures:

* No duplicate users or groups
* No unnecessary API calls
* Safe re-execution

---

## Logging and Validation

All scripts generate output files:

* student results
* staff provisioning results
* group creation results
* group assignment results

These are used for:

* Validation
* Troubleshooting
* Audit tracking

---

## Key Benefits

* Scalable automation for large environments
* Minimal manual intervention
* Consistent identity structure
* Consistent, repeatable Azure infrastructure deployment
* Real-world production design
* Optimized Microsoft Graph and Azure Resource Manager usage

---

## Summary

PowerShell automation in CloudSchool provides a complete lifecycle across both identity and infrastructure:

* User and group provisioning (Entra ID / Graph SDK)
* Administrative Units and role delegation
* Azure infrastructure provisioning (resource groups, networking, storage)
* RBAC and policy assignment
* License assignment

This approach reflects real-world enterprise cloud administration practices.
