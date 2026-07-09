# Task 10 — Storage Account

## Overview

This task provisions the primary Azure Storage Account for CloudSchool: `stcloudschoolprod001`, deployed into `RG-Storage-Prod`. The storage account is the foundation for later tasks (T11 Blob, T12 File Share, T13 Access Tiers, T14 Storage Access) — all of them build on top of this single account rather than creating separate ones per service type.

In the context of CloudSchool, this storage account will eventually hold blob data (e.g. document storage, backups) and file shares (e.g. shared drives for staff), while staying locked down at the network and data-access level until private endpoints are configured in T14.

## Design Decisions

| Decision | Value | Rationale |
|---|---|---|
| Redundancy | LRS (Locally Redundant Storage) | Portfolio project with no real disaster-recovery requirement or business continuity SLA. ZRS/GRS would add cost with no corresponding benefit here. Documented explicitly so the choice reads as deliberate, not default, in review. |
| Account kind | StorageV2 (general purpose v2) | Supports all four storage services (Blob, File, Queue, Table) and is the current recommended kind for new deployments — Storage V1 is legacy. |
| Performance tier | Standard | Premium is for high-IOPS/low-latency workloads (e.g. VM disks); not needed here. |
| Access tier | Hot | Data is expected to be actively used during the build/demo phase. Tiering strategy (Cool/Archive) is addressed properly in T13, not decided prematurely here. |
| Blob public access | Disabled (`AllowBlobPublicAccess = false`) | No blob should be readable anonymously by default. Any controlled external access will go through SAS tokens or RBAC, addressed in T14. |
| Public network access | Left at default (Enabled) — **not addressed in this task** | Deliberately deferred to T14, where private endpoints will be configured. Locking down network access now, before the private endpoint exists, would just require reopening it later — sequencing it at T14 avoids rework. |
| TLS minimum version | TLS 1.2 | Azure's current security baseline; TLS 1.0/1.1 are deprecated and vulnerable. |
| Secure transfer (HTTPS) | Required/Enabled | Prevents any HTTP (unencrypted) access to the storage account. |
| Hierarchical Namespace (HNS) | Disabled | HNS turns the account into Data Lake Storage Gen2 (optimized for big-data/analytics workloads with a real folder hierarchy). CloudSchool doesn't need that — it's a straightforward blob/file store, not an analytics platform. **Note: this is a one-time, creation-only decision** — HNS cannot be toggled after the account exists. |
| Tags | `Environment=Prod`, `Project=CloudSchool` | Consistent with tagging applied to Resource Groups (T7) and VNets (T7), for cost tracking and resource organization. |

## Prerequisites

- `RG-Storage-Prod` resource group must already exist (created in T7 via `07-create-resource-groups.ps1`)
- Az PowerShell module installed, specifically `Az.Storage` (v9.6.1 confirmed compatible) and `Az.Accounts`
- Authenticated session via `Connect-AzAccount -TenantId "401bd5c7-e8b2-4bee-83f6-abf0bad3b953"`
- Execution policy set for the session: `Set-ExecutionPolicy Bypass -Scope Process`
- If the script file was downloaded (not authored directly in the repo), it may carry Windows' "Mark of the Web" flag and needs `Unblock-File` before it will run

## CSV Structure

File: `03-CSV-Templates/storage-accounts.csv`

| Column | Description |
|---|---|
| `StorageAccountName` | Globally unique name, 3–24 characters, lowercase letters/digits only |
| `ResourceGroupName` | Target resource group (must already exist) |
| `Location` | Azure region (`uaenorth`) |
| `SkuName` | Redundancy + tier, e.g. `Standard_LRS` |
| `Kind` | Account kind, e.g. `StorageV2` |
| `AccessTier` | `Hot`, `Cool`, or `Archive` |
| `EnableHttpsTrafficOnly` | `TRUE`/`FALSE` — enforces HTTPS-only access |
| `MinimumTlsVersion` | e.g. `TLS1_2` |
| `AllowBlobPublicAccess` | `TRUE`/`FALSE` — controls anonymous blob read access |
| `EnableHierarchicalNamespace` | `TRUE`/`FALSE` — Data Lake Gen2 toggle, creation-time only |
| `Environment` | Tag value, e.g. `Prod` |
| `Project` | Tag value, e.g. `CloudSchool` |

## Script Logic

`02-Scripts/16-create-storage-account.ps1` follows the standard CloudSchool automation pattern:

1. **Import** `storage-accounts.csv`
2. **Loop** through each row (currently one storage account, but the script supports multiple)
3. **Resolve dependency**: confirm the target resource group exists before attempting creation; fail clearly if it doesn't rather than letting Azure throw a less obvious error
4. **Idempotency check**: `Get-AzStorageAccount` — if the account already exists, skip creation but still proceed to the configuration step, so re-running the script corrects any drift rather than doing nothing
5. **Two-step create-then-configure**:
   - `New-AzStorageAccount` sets base properties (SKU, kind, tier, HTTPS enforcement, TLS version, HNS)
   - `Set-AzStorageAccount` applies `AllowBlobPublicAccess` and tags — these must be set in a separate call because `AllowBlobPublicAccess` is not an available parameter on `New-AzStorageAccount` in this module version
   - Both boolean fields and the tags hashtable are built from the CSV before either call, converting string values (`"TRUE"`/`"FALSE"`) to real PowerShell booleans via `[System.Convert]::ToBoolean()`
6. **Build result object**: captures every applied setting plus status (`Created` / `AlreadyExists-ConfigChecked` / `Failed`) and any error message
7. **Export**: writes a timestamped result CSV to `05-Outputs/`

**Note on Hierarchical Namespace**: it only appears in the `New-` call, never in `Set-`, because HNS cannot be changed after account creation. If this ever needs to change, the account must be deleted and recreated — there is no in-place toggle.

## PowerShell Execution

```powershell
# Connect
Connect-AzAccount -TenantId "401bd5c7-e8b2-4bee-83f6-abf0bad3b953"

# Allow script execution for this session
Set-ExecutionPolicy Bypass -Scope Process

# If the script file shows as blocked (downloaded from the internet)
Unblock-File -Path .\16-create-storage-account.ps1

# Run from inside 02-Scripts/
.\16-create-storage-account.ps1
```

## GUI Equivalent

**Create the storage account:**

1. Azure Portal → search **Storage accounts** → **+ Create**
2. **Basics** tab:
   - Subscription: `CloudSchool-Prod-Subscription`
   - Resource group: `RG-Storage-Prod`
   - Storage account name: `stcloudschoolprod001`
   - Region: `UAE North`
   - Performance: `Standard`
   - Redundancy: `Locally-redundant storage (LRS)`
3. **Advanced** tab:
   - Require secure transfer for REST API operations: leave **Enabled** (default)
   - Minimum TLS version: `Version 1.2`
   - Allow enabling anonymous access on individual containers: **uncheck this** — this is the portal control that corresponds to `AllowBlobPublicAccess = false`
   - Hierarchical namespace: leave **unchecked** (Disabled)
4. **Networking** tab: leave defaults for now — this gets addressed in T14
5. **Data protection / Encryption** tabs: leave defaults (no design decisions made here for T10)
6. **Tags** tab:
   - `Environment` = `Prod`
   - `Project` = `CloudSchool`
7. **Review + create** → **Create**

**Portal gotcha:** the "Allow Blob anonymous access" toggle appears in different places depending on portal version — sometimes on the Advanced tab during creation, sometimes only reachable afterward via **Configuration** blade. If it's not visible during creation, create the account first, then go to **Configuration** and set it there.

## Verification

**Portal:**
- Overview blade: confirm Performance = Standard, Replication = LRS, Account kind = StorageV2
- Configuration blade: confirm Minimum TLS = 1.2, Secure transfer = Enabled, Allow Blob anonymous access = Disabled
- Networking blade: confirm Public network access = Enabled (expected — not yet restricted, that's T14)
- Tags blade: confirm `Environment=Prod`, `Project=CloudSchool`
- Blob service section (Properties/Overview): confirm Hierarchical namespace = Disabled

**CLI/PowerShell:**
```powershell
Get-AzStorageAccount -ResourceGroupName "RG-Storage-Prod" -Name "stcloudschoolprod001" | Format-List
```

Cross-check every field against the result CSV exported to `05-Outputs/` — script output should match portal reality exactly. Any mismatch means either the script has a bug or something was changed manually in the portal outside the source-of-truth chain.

## Output

Script exports a timestamped result CSV to `05-Outputs/storage-accounts-result-<timestamp>.csv`, containing: storage account name, resource group, location, SKU, kind, access tier, blob public access setting, minimum TLS version, HNS setting, applied tags, status, error message (if any), and execution timestamp.
