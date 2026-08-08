# Task 11 — Blob Storage

## Overview

This task provisions the blob container structure on the CloudSchool production
storage account, `stcloudschoolprod001`, and enables soft delete protection on
the blob service.

Blob storage is where CloudSchool holds unstructured, application-facing data:
student assignment uploads, generated report cards, curriculum material,
examination papers, media, website assets and long-term alumni archives. Access
is over HTTPS/REST rather than SMB, so blob is the correct service for data that
applications read and write, and for data that is archived rather than actively
edited.

Containers are defined in CSV and created by script. Authentication to the data
plane uses the signed-in Entra ID identity rather than storage account keys.

Human-facing shared drives — the kind staff map as a network drive in File
Explorer — are deliberately **not** in scope here. Those require SMB and belong
to Azure Files, covered in Task 12.

---

## Design Decisions

### Container count is driven by access boundaries, not organisational structure

Blob storage has a flat namespace when hierarchical namespace (HNS) is disabled,
which is the case on this account. A blob named
`grade01/divisiona/std01a001/essay.pdf` is a single object whose name happens to
contain forward slashes. No folder objects exist. The portal parses the
delimiter and renders a folder tree, but nothing is created and nothing persists
once the blobs are removed.

This means a container per grade, per division or per department would be
pointless — one container can hold unlimited virtual hierarchy under prefixes.

What a container *does* provide is a security boundary. It is the lowest scope
at which an Azure RBAC role assignment can be made. The design rule follows
directly: **one container per distinct set of principals.** Two datasets read and
written by the same people belong in one container under different prefixes.
Two datasets needing different permissions need different containers.

### Container inventory

| Container | Contents | Write | Read |
|---|---|---|---|
| `student-submissions` | Assignment uploads, prefixed by grade, division and student | Students | Class teachers, grade coordinators |
| `student-records` | Report cards and transcripts | Management | Management, grade coordinators |
| `staff-resources` | Curriculum, lesson plans, policy documents | Management, department heads | All staff |
| `exam-papers` | Pre-release examination papers | Principal, department heads | Principal, department heads |
| `school-media` | Event photography, prospectus imagery | Staff | All staff |
| `public-website` | Static assets for the school website | IT | Delivered via SAS or CDN |
| `archive-alumni` | Graduated student records held for compliance | IT | IT |

Each row has a different principal set, which is what justifies it as a separate
container.

### Containers considered and rejected

**`diagnostic-logs`** — rejected. When a diagnostic setting is pointed at a
storage account, Azure creates and names its own containers (of the form
`insights-logs-<category>`). A user-created container of this name would never
receive data. Task 28 will rely on the platform-created containers.

**`vm-backups`** — rejected. Azure Backup for virtual machines writes to a
Recovery Services Vault backed by Microsoft-managed storage. A customer blob
container cannot be nominated as the backup destination. Task 30 will use a
vault.

This principle was confirmed independently during verification: a container named
`$logs` exists on the account and was not created by this task. It belongs to
Storage Analytics logging and is owned by the platform. Note that its name begins
with `$`, which would be rejected if a user attempted to create it — system
containers are exempt from the naming rules below.

> **VERIFY BEFORE FINALISING:** confirm the origin of `$logs` by checking
> Monitoring → Diagnostic settings (classic) on the storage account. Its
> timestamp is close to the T11 script run, so it is unclear whether it predates
> this task or was created alongside it.

### Naming convention deviation

Blob container names must be lowercase, 3–63 characters, restricted to letters,
numbers and hyphens, must begin and end with a letter or number, and may not
contain consecutive hyphens.

The `PascalCase-With-Hyphens` convention used elsewhere in CloudSchool for
resource groups and virtual networks is therefore invalid for containers. All
container names use lowercase with hyphens. This is a service constraint, not an
inconsistency in the project's naming standard.

### Entra ID authentication over account keys

The script authenticates to the data plane with the signed-in Entra identity via
`New-AzStorageContext -UseConnectedAccount`, not with an account key.

Account keys grant unrestricted access to every service in the storage account,
cannot be scoped to an individual container, cannot be attributed to a person in
the audit log, and would have to be retrieved or stored at runtime. Entra
authentication avoids all four problems and allows per-container role
assignments in future tasks.

### Control plane and data plane are separate permission systems

This distinction determined the prerequisites for the whole task.

Azure separates storage operations into two planes with independent
authorisation:

- **Control plane** — managing the account itself: creating it, configuring
  soft delete, reading keys. Governed by roles such as Owner and Contributor.
- **Data plane** — reading and writing the blobs inside: uploading, downloading,
  listing, creating containers. Governed by the `Storage Blob Data *` roles.

Subscription Owner is a control-plane role and confers **no** data-plane access.
Creating containers with Entra authentication therefore required an explicit
`Storage Blob Data Contributor` assignment on the storage account.

The one qualification is that Owner can read the account keys, and a key bypasses
Entra entirely. This is an indirect route to the data, and a reason not to leave
keys in circulation.

Script 17 exercises both planes: soft delete configuration is a control-plane
call taking resource group and account name, while container creation is a
data-plane call taking a storage context.

### RBAC schema extension

`rbac-assignments.csv` stored scope as a `ScopeType` plus a `ScopeName`,
supporting only `Subscription` and `ResourceGroup`. A resource-level scope
requires resource group, provider namespace, resource type and resource name —
which two fields cannot express.

A third `ScopeType` value, `Resource`, was added. When it is used, `ScopeName`
holds the complete resource ID and the script consumes it directly after
validating the resource exists.

This was chosen over adding `ResourceType` and `ResourceName` columns because no
existing row changes, no per-provider scope construction is required, and the
same branch will serve private endpoints (T14), Log Analytics (T27) and Recovery
Services vaults (T30) without further schema changes. The cost is a duplicated
subscription ID inside that cell, which is acceptable in a source-of-truth file
where explicitness matters more than compactness.

### Soft delete at 7 days

Blob soft delete and container soft delete are both enabled with a 7-day
retention window. For an environment holding student records, accidental
deletion must be recoverable — a teacher clearing a folder of submissions should
not be a data-loss event.

Seven days is long enough to demonstrate and test recovery while keeping
retained-data costs negligible in a lab subscription.

`AllowPermanentDelete` was deliberately left disabled. It permits hard-deleting
soft-deleted items and would weaken the protection just enabled.

Versioning and change feed were **not** enabled. Both incur ongoing storage cost
and neither has a current use case in CloudSchool.

### Deferred to later tasks

- **Access tiers and lifecycle management** — Task 13. `archive-alumni` is the
  natural candidate for a Cool or Archive tier and a lifecycle rule.
- **SAS tokens** — Task 14. `public-website` is the natural demonstration.
- **Container-scoped RBAC** — the role assignments described in the container
  table above are the intended design; implementing them per container is future
  work.
- **Immutability policies** — time-based retention and legal hold are relevant to
  `exam-papers` and `student-records` in a real school, but an immutability
  policy cannot easily be removed once applied and would obstruct further lab
  work.
- **Container metadata** — omitted. Setting it from PowerShell goes through the
  underlying .NET client object rather than a dedicated cmdlet, and the syntax
  has varied between Az.Storage generations. The added fragility is not
  justified.

---

## Prerequisites

1. Storage account `stcloudschoolprod001` exists in `RG-Storage-Prod`
   (Task 10).
2. `Storage Blob Data Contributor` assigned to the administrator account at
   resource scope on the storage account. Without this, container creation fails
   with a 403 that resembles a bug rather than a permissions gap. Role
   assignments take a few minutes to propagate.
3. `Az.Storage` module — verified against version 9.6.0.
4. Connected to Azure:
   `Connect-AzAccount -TenantId 401bd5c7-e8b2-4bee-83f6-abf0bad3b953`

The role assignment in item 2 was added as a row to `rbac-assignments.csv` and
applied through `14-assign-rbac-roles.ps1`, not created directly in the portal.

---

## CSV Structure

### `blob-containers.csv`

| Column | Description |
|---|---|
| `ContainerName` | Container name. Lowercase, hyphen-separated, must satisfy Azure container naming rules. |
| `PublicAccess` | Anonymous access level. `Off` on every row. |
| `Purpose` | Plain-language description of the container's role. Carried into the output report and this document. |

### `blob-service-properties.csv`

Account-level settings, one row per storage account. Kept separate from the
container CSV because the cardinality differs — repeating a single account-wide
value across seven container rows invites divergence.

| Column | Description |
|---|---|
| `StorageAccountName` | Target storage account. |
| `ResourceGroupName` | Resource group containing the account. |
| `BlobSoftDeleteEnabled` | Boolean. Enables blob-level soft delete. |
| `BlobSoftDeleteRetentionDays` | Integer. Retention window for deleted blobs. |
| `ContainerSoftDeleteEnabled` | Boolean. Enables container-level soft delete. |
| `ContainerSoftDeleteRetentionDays` | Integer. Retention window for deleted containers. |

Boolean values arrive from `Import-Csv` as strings, and any non-empty string is
truthy in PowerShell — `"False"` evaluates as true. They are converted with
`[System.Convert]::ToBoolean()`.

---

## Script Logic

`02-Scripts/17-create-blob-containers.ps1`

1. **Preflight.** Confirm both CSVs exist, create the output folder if missing,
   confirm an Azure context is present and that it is connected to the expected
   tenant. Fail early with a clear message rather than partway through.
2. **Read account settings.** Take the first row of the service properties CSV
   and convert the boolean and integer fields.
3. **Apply soft delete (control plane).** Branch on the CSV booleans and call the
   appropriate enable or disable cmdlet for blob and container retention.
4. **Build the storage context (data plane).** Create a context bound to the
   signed-in Entra identity.
5. **Loop containers.** For each row: validate the name is lowercase, then
   attempt to retrieve the container.
6. **Idempotency.** If the container does not exist, create it. If it exists,
   compare its public access level against the CSV and correct only if they
   differ.
7. **Record the outcome.** Build a result object per row with an action of
   `Created`, `AlreadyExists`, `Updated` or `Failed`, plus the failure message
   where relevant.
8. **Export.** Write all results to a timestamped CSV in `05-Outputs/` and print
   a grouped summary.

### Az.Storage 9.6.0 cmdlet behaviour

`Update-AzStorageBlobServiceProperty` does **not** expose soft delete parameters
in this module version. It handles only `DefaultServiceVersion`,
`EnableChangeFeed`, `ChangeFeedRetentionInDays`, `IsVersioningEnabled` and
`CorsRule`.

Retention policies are configured through dedicated cmdlets:

- `Enable-AzStorageBlobDeleteRetentionPolicy` / `Disable-…`
- `Enable-AzStorageContainerDeleteRetentionPolicy` / `Disable-…`

Because these are enable/disable pairs rather than a single cmdlet accepting a
boolean, the script branches on the CSV value instead of passing it through.

Parameter names were confirmed against the installed module with
`Get-Command <name> -Syntax` before the script was written. Module versions
differ in this area and published examples are frequently written against a
different generation.

### Null handling on `PublicAccess`

When anonymous access is disabled at account level, the `PublicAccess` property
of a retrieved container returns null rather than the string `Off`. A direct
comparison against `Off` would report drift on every container on every run and
trigger an unnecessary ACL write each time. The script normalises null to `Off`
before comparing. The idempotent re-run producing seven `AlreadyExists` and zero
`Updated` confirms this works.

---

## PowerShell Execution

```powershell
Set-ExecutionPolicy Bypass -Scope Process

Connect-AzAccount -TenantId "401bd5c7-e8b2-4bee-83f6-abf0bad3b953"

cd G:\CloudSchool-Cloud-Administration-Project\02-Scripts
.\17-create-blob-containers.ps1
```

Paths are resolved with `$PSScriptRoot`, so the script can be run from any
working directory.

Run from a normal PowerShell 7 session. Administrator sessions are used only for
module installation in this project.

---

## GUI Equivalent

### Creating a container

1. Azure Portal → **Storage accounts** → `stcloudschoolprod001`
2. Left menu → **Data storage** → **Containers**
3. Click **+ Container**
4. Enter the container name (lowercase, hyphens only)
5. **Anonymous access level** — see gotcha 1 below
6. Optionally expand **Advanced** to select an encryption scope
7. Click **Create**

### Enabling soft delete

1. Storage account → **Data management** → **Data protection**
2. Tick **Enable soft delete for blobs**, set retention to 7 days
3. Tick **Enable soft delete for containers**, set retention to 7 days
4. Leave **Enable permanent delete for soft deleted items** unticked
5. Click **Save**

### Browsing blobs

Storage account → **Storage browser** → **Blob containers**. Provides an
in-portal file browser without installing Azure Storage Explorer.

### Recovering a deleted blob

1. **Storage browser** → open the container
2. Change the filter dropdown from **Only show active blobs** to **Show active
   and deleted blobs**
3. Navigate the prefix path to the blob — it appears with a **Deleted** status
   and a remaining retention count
4. Select the blob and click **Undelete**

Note that with the filter set to active blobs only, the virtual folder path also
disappears, because folders exist only as prefixes on active blobs.

### Portal gotchas

**1. Anonymous access level is disabled.** Because `AllowBlobPublicAccess` is
false at account level, the dropdown is greyed out and the portal displays:
*anonymous access to this container is being blocked because anonymous access is
disabled on this storage account*. The account-level setting overrides any
container-level configuration. Anonymous access cannot be enabled on any
container regardless of what the container specifies.

**2. Storage Browser defaults to access key authentication.** The authentication
method is shown above the blob list and defaults to **Access key**, not the
signed-in Entra account. A **Switch to Microsoft Entra user account** link
toggles it. If a user lacks an appropriate `Storage Blob Data *` role, switching
produces an access-denied error that can be mistaken for a broken container.

**3. Soft delete is two separate settings.** Blob soft delete and container soft
delete are independent checkboxes on the same blade. Enabling one does not enable
the other.

**4. Retention counts down from the current partial day.** A blob deleted under a
7-day policy reports 6 remaining days almost immediately. This is expected and
does not indicate a misconfigured policy.

---

## Verification

### PowerShell

```powershell
# Soft delete configuration
Get-AzStorageBlobServiceProperty `
    -ResourceGroupName "RG-Storage-Prod" `
    -StorageAccountName "stcloudschoolprod001"

# Container inventory
$ctx = New-AzStorageContext -StorageAccountName "stcloudschoolprod001" -UseConnectedAccount
Get-AzStorageContainer -Context $ctx | Select-Object Name, PublicAccess, LastModified

# Soft-deleted blob state
Get-AzStorageBlob -Container "student-submissions" -Context $ctx -IncludeDeleted |
    Select-Object Name, IsDeleted, DeletedOn, RemainingDaysBeforePermanentDelete
```

### Idempotency

The script was run twice in succession. The first run reported seven `Created`.
The second reported seven `AlreadyExists` and zero `Updated`, confirming both
that the existence check works and that the public access comparison does not
produce false drift.

### Virtual folder behaviour

A test blob was uploaded to `student-submissions` with the name
`grade01/divisiona/std01a001/test-submission.txt`. PowerShell reported a single
block blob of 55 bytes. The portal rendered three nested folders derived from the
delimiters, demonstrating that the hierarchy is presentational only.

### Soft delete

The test blob was deleted. `Get-AzStorageBlob -IncludeDeleted` reported
`IsDeleted = True` with 6 remaining days, and the portal listed it with a
**Deleted** status under the show-deleted filter. This confirms the blob is
retained and in a recoverable state. Restoration was not performed — the blob is
allowed to expire under the retention policy.

### Screenshots

| File | Evidence |
|---|---|
| `T11-01-Script-Run-Created.png` | First run, seven containers created |
| `T11-02-Script-Run-Idempotent.png` | Second run, seven already exist |
| `T11-03-Containers-Blade.png` | Portal container listing |
| `T11-04-Data-Protection-Soft-Delete.png` | Both soft delete policies at 7 days |
| `T11-05-Anonymous-Access-Disabled.png` | Account-level override blocking container-level anonymous access |
| `T11-06-Storage-Browser.png` | Storage Browser container view |
| `T11-07-Virtual-Folder-Structure.png` | Portal-rendered folders from a single slashed blob name |
| `T11-08-Soft-Delete-Verification-PowerShell.png` | Deletion and retained state from PowerShell |
| `T11-09-Soft-Deleted-Blob-Portal-Deleted.png` | Deleted blob visible with retention countdown |

---

## Output

`05-Outputs/blob-containers-result-<yyyyMMdd-HHmmss>.csv`

| Column | Description |
|---|---|
| `ContainerName` | Container processed |
| `Purpose` | Carried from the input CSV |
| `PublicAccessRequested` | Value specified in the CSV |
| `PublicAccessActual` | Value observed after the operation |
| `Action` | `Created`, `AlreadyExists`, `Updated` or `Failed` |
| `Message` | Failure detail or description of a correction |
| `StorageAccount` | Target account |
| `ResourceGroup` | Containing resource group |
| `RunTimestamp` | Run identifier, matching the filename |

Output is timestamped per run so history is preserved rather than overwritten.
`05-Outputs/` is gitignored.

---

## Process Note

The `Storage Blob Data Contributor` assignment was initially created in the Azure
Portal while diagnosing the data-plane permissions requirement. This left
`rbac-assignments.csv` out of step with the live tenant.

It was corrected by adding the row to the CSV, extending the scope builder in
script 14 to handle resource scopes, and re-running the script — which reported
all twelve assignments as already present, confirming the CSV and the tenant
agree.

Role assignments flow CSV → script → Azure. The portal is used for verification
only.
