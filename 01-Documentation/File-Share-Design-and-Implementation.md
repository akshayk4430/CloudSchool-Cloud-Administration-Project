# Task 12 — Azure File Shares

## Overview

This task provisions five SMB file shares on the existing CloudSchool storage account, driven by a CSV that acts as the single source of truth.

CloudSchool needs file shares to support everyday school operations: a common area for staff to exchange documents, a workspace for student assignments, a read-mostly library of school templates and forms, and separate departmental areas for IT and Accounts. Unlike blob containers, file shares can be mounted as a network drive, so staff work with them exactly as they would a traditional file server.

This continues the storage work started in T10, which created the storage account, and T11, which created blob containers in its blob service. This task uses the file service on the same account.

---

## Design Decisions

### 1. File shares rather than blob containers

Blob containers have a flat namespace. What looks like a folder is only a prefix in the blob's name — delete the last blob under `grade01/assignments/` and the "folder" disappears with it. Containers are also accessed over HTTPS by applications, not mounted by users.

File shares behave like a real file system. Directories exist independently of their contents, and the share can be mounted as a drive letter (for example `S:\`) on a Windows client. For a school where staff open, edit and save documents directly, this is the correct service — the workflow matches a traditional on-premises file server with no change in how people work.

### 2. No identity-based SMB access

Azure Files supports three identity sources for SMB authentication: on-premises AD DS, Microsoft Entra Kerberos, and Microsoft Entra Domain Services. None was implemented, for two distinct reasons.

**Entra Kerberos was ruled out by architecture, not cost.** The feature itself is available at no charge, but it authenticates *hybrid* identities — accounts synced into Entra ID from an on-premises AD DS. CloudSchool is a cloud-only tenant; all ~555 accounts were created directly in Entra ID and have no on-premises counterpart. Entra Kerberos cannot authenticate them.

**Entra Domain Services was ruled out on cost.** It is the supported workaround for cloud-only tenants: a managed domain that cloud accounts can authenticate against. It is a paid service billed continuously, requires a dedicated subnet, and would exceed the budget for this project by a wide margin for a capability that is not required to demonstrate the storage concepts in scope.

The consequence is documented rather than hidden: shares created in this task are mounted using the storage account key, which is shared-secret authentication rather than per-user identity. In a production school this would be revisited — the prerequisite is understood, and the constraint is a property of the tenant, not an oversight.

### 3. Large file shares left disabled

Standard file shares are capped at 5 TiB. Enabling `LargeFileSharesState` on the storage account raises this to 100 TiB, but the change is **irreversible and permanently prevents converting the account to geo-redundant storage**.

CloudSchool has no capacity requirement anywhere near 5 TiB — the largest share is provisioned at 200 GiB. Keeping the option to convert `stcloudschoolprod001` from LRS to GRS later is worth more than a ceiling that will never be reached, so the feature was left off.

Verified after provisioning: querying `LargeFileSharesState` on the storage account returns empty, confirming it has never been enabled. The Azure Portal displays "Maximum storage (GiB): 102400" on the share properties blade — this is the service maximum shown for reference, not the configured limit for this share, and should not be read as evidence that large file shares are on.

### 4. Access tier assigned per share by usage

Standard file shares support three access tiers, and the tier is set on the share, not the account. Because the five shares have different access patterns, applying one tier to all of them would either overpay for storage or overpay for transactions.

| Share | Tier | Reasoning |
|---|---|---|
| `staff-shared` | Hot | Accessed daily by all staff |
| `it-department` | TransactionOptimized | Frequent small reads and writes; transaction cost dominates storage cost |
| `accounts-department` | Hot | Regular working access by the Accounts team |
| `school-templates` | Cool | Read-mostly reference material, rarely modified |
| `student-workspace` | Hot | Active assignment submission and retrieval |

Note that this tier is entirely separate from the blob access tier configured on the same storage account in T10 — they are different services and the settings do not interact.

### 5. Management plane rather than data plane

Azure Files exposes two distinct APIs, and the script deliberately uses only one.

The **management plane** (ARM) creates, configures and deletes the share as an Azure resource. Its cmdlets carry the `Rm` prefix — `New-AzRmStorageShare`, `Get-AzRmStorageShare` — and authorisation comes from Azure RBAC. Because the project owner already holds Owner on the subscription, no storage account key or connection string is needed anywhere in the script.

The **data plane** reads and writes the files *inside* the share. Its cmdlets have no `Rm` prefix, and authorisation requires the account key, a SAS token, or a domain identity over SMB. The Entra ID data roles that work for blob data do not apply to SMB access.

Provisioning is a management-plane concern, so the script stays entirely on that side. This keeps account keys out of the automation completely — the same reasoning that made key-free provisioning possible in T11, arrived at by a different route.

### 6. Soft delete left at the Azure default — not enforced

The file service on `stcloudschoolprod001` has soft delete enabled with a 7-day retention period. This is Azure's default for a new storage account; **it was not configured by any script in this project.**

Recording it accurately matters. A setting that happens to be correct is not the same as a setting the automation guarantees, and documenting an inherited default as a deliberate configuration would misrepresent what the code does. The current state is safe, but nothing prevents it from drifting.

Enforcing blob and file service soft delete through `16-create-storage-account.ps1` and `storage-accounts.csv` is tracked separately as **T10.1** and will be delivered on its own branch, so that an account-level change is not mixed into a file-share feature.

---

## Prerequisites

Before running `18-create-file-shares.ps1`:

- An authenticated Azure session on the CloudSchool tenant — `Connect-AzAccount -TenantId 401bd5c7-e8b2-4bee-83f6-abf0bad3b953`
- The active context must be set to `CloudSchool-Prod-Subscription`; the script's guard blocks execution otherwise
- Storage account `stcloudschoolprod001` must already exist in `RG-Storage-Prod`, created by `16-create-storage-account.ps1`
- The `Az.Storage` module must be available (developed and tested against 9.6.0)
- Sufficient RBAC rights on the storage account to create file shares
- `03-CSV-Templates/file-shares.csv` must be present and populated
- The script uses relative paths and must be run from the repository root

---

## CSV Structure

Source file: `03-CSV-Templates/file-shares.csv`

| Column | Description | Example |
|---|---|---|
| `ShareName` | Name of the file share. Lowercase, 3–63 characters, alphanumeric and hyphens only. Must be unique within the storage account. | `staff-shared` |
| `StorageAccountName` | Storage account hosting the share. | `stcloudschoolprod001` |
| `ResourceGroupName` | Resource group containing the storage account. | `RG-Storage-Prod` |
| `QuotaGiB` | Maximum share size in GiB. Acts as a ceiling only — billing is based on data actually stored. | `100` |
| `AccessTier` | One of `TransactionOptimized`, `Hot`, or `Cool`. | `Hot` |

`Import-Csv` returns every value as a string, so `QuotaGiB` is cast to an integer before being passed to the cmdlet.

---

## Script Logic

**Context guard.** The script first confirms an authenticated Azure session exists, and that it is pointing at the expected tenant and subscription. If any of the three checks fails, the script throws immediately rather than continuing. Failing here is cheap; discovering the wrong context after provisioning has started is not.

**Import.** The share definitions are read from `file-shares.csv`, and an empty array is declared to collect the run results.

**Per-iteration reset.** The loop begins by setting `$shareObject` to `$null`. Without this, a failed create would leave the previous share's object in the variable, and the failed row would report that share's tier and quota while claiming a status of Failed. Clearing it first means a failure produces empty fields rather than someone else's values.

**Existence check.** One API call is made per share, querying that specific share on the storage account named in its own CSV row. Querying per share rather than listing every share up front keeps the check correct when rows point at different storage accounts — share names are only unique within an account, so a name-only comparison against a single account's contents could match the wrong resource. At five to twenty shares the additional calls cost a few seconds, which is not a meaningful trade against correctness.

**If the share exists.** `$shareObject` is assigned the object returned by the query, and status is set to `Exists`. Nothing is created. The assignment matters because the result row is built from this object rather than from the CSV.

**If the share does not exist.** The create call runs inside a `try` block with `-ErrorAction Stop`. Most Az cmdlets raise non-terminating errors by default: without `-ErrorAction Stop` the error would print, `catch` would never fire, and the script would record a status of `Created` for a share that was never provisioned — a silent failure that is difficult to trace later. With it, the error terminates the `try` block, execution jumps to `catch`, the failure is written as a warning including the message Azure returned, and status is set to `Failed`. The loop then continues to the next share; a single failure does not end the run.

**Result object.** Each iteration appends a `PSCustomObject` to the results array. `AccessTier` and `QuotaGiB` are read from `$shareObject`, so the log reflects what Azure actually provisioned rather than what the CSV requested.

**Output.** After the loop completes, the results are displayed as a table for the console and exported to CSV as the run log.

### Known limitation

The script does not check whether the imported CSV contains any rows. An empty or malformed CSV would produce a loop that never executes and an empty output file, with no indication that anything was wrong. Adding a row-count check after import is tracked as a follow-up item.

---

## PowerShell Execution

Run from the repository root, in PowerShell 7.

```powershell
# Allow local scripts for this session only. A fresh Windows install defaults to
# Restricted, which blocks script files. -Scope Process limits the change to the
# current session rather than altering machine-wide policy.
Set-ExecutionPolicy Bypass -Scope Process

# Connect to the CloudSchool tenant. 10-connect-AzAccount.ps1 in this repo does
# the same thing.
Connect-AzAccount -TenantId "401bd5c7-e8b2-4bee-83f6-abf0bad3b953"

# The script uses relative paths, so the working directory must be the repo root.
cd <path-to-repo>

# Run the script.
.\02-Scripts\18-create-file-shares.ps1
```

On a work machine subject to corporate SSL inspection, interactive sign-in may fail. Use `Connect-AzAccount -TenantId "..." -UseDeviceAuthentication` instead.

---

## GUI Equivalent

### Creating a file share

1. Sign in to the Azure Portal and navigate to **Storage accounts**
2. Select `stcloudschoolprod001`
3. In the left menu, expand **Data storage** and select **Classic file shares**
4. Click **+ Classic file share**
5. On the **Basics** tab, provide:
   - **Name** — must be unique within this storage account. Lowercase, 3–63 characters, alphanumeric and hyphens only.
   - **Access tier** — Transaction optimized, Hot, or Cool. Defaults to Transaction optimized.
6. On the **Backup** tab, review the settings (see gotchas below)
7. Click **Review + create**, then **Create**

### Setting the quota

The create panel has no quota field. To set it after creation, open the share, select **Edit quota** from the toolbar, enter the value in GiB, and click OK.

This is a real difference from the scripted approach: `New-AzRmStorageShare` accepts `-QuotaGiB` at creation, so the script does in one step what the portal requires two for.

### Portal gotchas

- **Backup is enabled by default** on the Backup tab, pre-filled with a new Recovery Services Vault and a daily retention policy. Clicking through without reviewing creates a vault that was never requested and starts incurring backup charges. Azure Backup is a paid service. The script creates none of this.
- **"Maximum capacity: 100 TiB"** is displayed on both the create panel and the share properties blade. This is the service ceiling with large file shares enabled, not the limit that applies here — large file shares are disabled on this account, so the real cap is 5 TiB. The display is misleading and should not be read as evidence of the account's configuration.
- **The blade is named "Classic file shares"**, not "File shares". Documentation and tutorials referring to a "File shares" blade are describing a different portal layout.
- **SMB requires outbound TCP port 445.** Many residential ISPs and corporate networks block it. A share that mounts on one network and fails on another is almost always hitting this, not an Azure misconfiguration — checking the network path first saves troubleshooting in the wrong layer.

### Verification in the portal

Navigate to the storage account, then **Data storage** → **Classic file shares**. The list view shows every share with its access tier and quota, which is enough to confirm the script's output in a single view.

---

## Verification

**Script output.** The first run reported five shares as `Created`. Re-running the script immediately afterwards reported all five as `Exists` with no creates attempted, confirming idempotency.

**Error handling.** A row with an invalid share name (`Test_Invalid_NAME` — uppercase is not permitted) was temporarily added to the CSV. The run produced a warning carrying Azure's own error message, recorded that row as `Failed` with empty tier and quota, and continued to process the remaining shares normally. The test row was then removed.

**Portal.** The Classic file shares blade on `stcloudschoolprod001` shows all five shares with tiers and quotas matching the CSV: `staff-shared` Hot 100 GiB, `it-department` Transaction optimized 100 GiB, `accounts-department` Hot 50 GiB, `school-templates` Cool 50 GiB, `student-workspace` Hot 200 GiB. Redundancy is LRS and the location is UAE North, inherited from the storage account.

**Identity-based access.** The share properties blade confirms Directory service is Not configured, matching the design decision above.

**Large file shares.** Querying `LargeFileSharesState` on the storage account returns empty, confirming the feature has never been enabled and the GRS conversion path remains open.

Screenshots: `04-Screenshots/`

---

## Output

The script writes a run log to `05-Outputs/t12-file-shares.csv` (gitignored). One row per share in the input CSV:

| Column | Description |
|---|---|
| `ShareName` | Share name, taken from the input CSV |
| `AccessTier` | Tier reported by Azure on the returned share object |
| `Status` | `Exists`, `Created`, or `Failed` |
| `QuotaGiB` | Quota reported by Azure on the returned share object |
| `Timestamp` | Time the row was written |

`AccessTier` and `QuotaGiB` are read from the object Azure returns rather than from the input CSV, so the log records what was actually provisioned rather than what was requested. On a `Failed` row both columns are empty, because the per-iteration reset clears the variable and no object is returned — an empty value is correct here, where a carried-over value from the previous share would be silently wrong.
