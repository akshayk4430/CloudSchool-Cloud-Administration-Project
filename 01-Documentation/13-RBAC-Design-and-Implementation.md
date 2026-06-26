# 13 - Azure RBAC Design and Implementation

## What is Azure RBAC

Azure Role-Based Access Control (RBAC) is the authorization system that controls who can do what on which Azure resources. Every action in Azure — creating a VM, reading a storage account, deleting a resource group — is governed by RBAC.

Every RBAC assignment is built on three components:

- **Security Principal** — who is getting access (user, group, service principal, or managed identity)
- **Role Definition** — what they are allowed to do (a collection of permissions)
- **Scope** — where those permissions apply (subscription, resource group, or individual resource)

All three must be defined for an assignment to exist.

---

## Core Built-in Roles

Azure has over 100 built-in roles, but three are fundamental and cover most real-world scenarios:

| Role | What it can do | What it cannot do |
|---|---|---|
| Reader | View all resources | Make any changes |
| Contributor | Create and manage resources | Manage access (no role assignments) |
| Owner | Full control including access management | Nothing — has everything |

**Critical exam point:** Contributor cannot assign roles. This is the most common exam trap. A Contributor can create, modify, and delete resources — but they cannot grant or remove access to anyone. Only Owner can do that.

---

## Scope and Inheritance

Azure scopes follow a strict hierarchy:

```
Management Group
    └── Subscription
            └── Resource Group
                    └── Resource
```

Permissions assigned at a higher scope **inherit downward automatically**. If a group is assigned Reader at the subscription level, they have Reader access on every resource group and every resource inside that subscription — with a single assignment.

This was visible in the CloudSchool portal verification. GRP-Staff-Management was assigned Reader at the subscription level. When viewing RG-Compute-Prod's IAM blade, GRP-Staff-Management appeared with scope marked as **Subscription (Inherited)** — meaning the permission came from above, not from a direct assignment on the RG.

In contrast, GRP-Staff-IT was assigned Contributor directly on each resource group. In the portal it showed as **This resource** — scoped only to that specific RG.

---

## Azure RBAC vs Entra ID Roles

These are two completely separate systems and are a common source of confusion:

| | Azure RBAC | Entra ID Roles |
|---|---|---|
| Controls | Azure resources (VMs, storage, RGs, subscriptions) | Entra ID objects (users, groups, applications) |
| Assigned via | IAM blade on any Azure resource | Entra ID → Roles and Administrators |
| Example role | Contributor on RG-Compute-Prod | Helpdesk Administrator scoped to an AU |
| CloudSchool task | Task 8 — this document | Task 7 — Role Delegation |

In CloudSchool, Task 7 used Entra ID roles to give Grade Coordinators and Class Teachers the ability to reset student passwords within their Administrative Unit scope. That had nothing to do with Azure resources.

Task 8 uses Azure RBAC to control who can manage the actual cloud infrastructure — resource groups, VNets, storage, compute. These are two different permission systems serving two different purposes.

---

## CloudSchool RBAC Design

The design follows the principle of least privilege — every principal gets only the access their role requires, nothing more.

| # | Principal | Type | Role | Scope | Reason |
|---|---|---|---|---|---|
| 1 | AkshayKattoth@CloudSchoolLabs.onmicrosoft.com | User | Owner | Subscription | Cloud Administrator — full control over entire environment |
| 2 | vishnu.prakash@cloudschool.ink | User | Owner | Subscription | IT Head (DeptHead) — full infrastructure ownership and access management |
| 3 | GRP-Staff-IT | Group | Contributor | RG-Compute-Prod | Manage compute infrastructure |
| 4 | GRP-Staff-IT | Group | Contributor | RG-Network-Prod | Manage networking resources |
| 5 | GRP-Staff-IT | Group | Contributor | RG-Storage-Prod | Manage storage resources |
| 6 | GRP-Staff-IT | Group | Contributor | RG-Monitoring-Prod | Manage monitoring resources |
| 7 | GRP-Staff-IT | Group | Contributor | RG-Compute-Dev | Full access to dev compute environment |
| 8 | GRP-Staff-IT | Group | Contributor | RG-Network-Dev | Full access to dev network environment |
| 9 | GRP-Staff-Management | Group | Reader | Subscription | Visibility across entire environment — no change rights |
| 10 | GRP-Staff-Accounts | Group | Reader | RG-Monitoring-Prod | Cost and billing visibility only |
| 11 | GRP-Staff-Operations | Group | Reader | RG-Compute-Prod | Operational visibility into compute workloads |

### Key Design Decisions

**Why Owner is assigned to individual users, not groups:**
Owner at subscription level is the most powerful assignment in the environment. Assigning it to a group risks accidental membership changes granting full control to unintended users. Keeping it to named individuals makes ownership explicit and auditable.

**Why IT staff get Contributor on resource groups, not the subscription:**
Assigning Contributor at subscription level would give IT staff the ability to manage every resource group including ones outside their responsibility. Scoping to specific resource groups enforces boundaries — IT staff can manage infrastructure but cannot touch the subscription itself or assign roles to anyone.

**Why Management gets Reader at subscription:**
A single subscription-level Reader assignment gives Management visibility across all six resource groups through inheritance. This is more efficient and easier to maintain than six separate resource group assignments.

**Why Accounts and Operations get Reader on specific resource groups only:**
These departments have no business reason to see the full Azure environment. Accounts only needs monitoring data for cost visibility. Operations only needs compute visibility for workload monitoring. Least privilege applied at its most granular.

**Why Vishnu Prakash required a data fix before this task:**
During RBAC design planning, it was identified that no staff member in the IT department had `DeptHead` assigned in `ExtensionAttribute1`. Vishnu Prakash was selected as IT Head and his attribute was corrected through the source-of-truth chain — `staff-attributes.csv` → `09-merge-staff-csv.ps1` → `staff-final.csv` → `03-create-staff.ps1` → Entra ID. This was committed separately under `fix/vishnu-depthead-attribute`.

---

## Implementation

### CSV Structure

File: `03-CSV-Templates/rbac-assignments.csv`

| Column | Purpose |
|---|---|
| `PrincipalName` | UPN for users, display name for groups |
| `PrincipalType` | User or Group — determines which lookup method the script uses |
| `RoleDefinitionName` | Exact Azure built-in role name |
| `ScopeType` | Subscription or ResourceGroup |
| `ScopeName` | Subscription name or resource group name |

### Script Logic

File: `02-Scripts/14-assign-rbac-roles.ps1`

1. Validates CSV exists and output directory is present
2. Fetches subscription ID automatically using the subscription name
3. For each row in the CSV:
   - Resolves the principal to an Object ID — `Get-AzADUser` for users, `Get-AzADGroup` for groups
   - Builds the full scope path — `/subscriptions/{id}` for subscription, resource group resource ID for RG
   - Checks if the assignment already exists using `Get-AzRoleAssignment`
   - Skips if it exists, assigns if it does not using `New-AzRoleAssignment`
   - Logs every outcome with status
4. Exports full results to `05-Outputs/rbac-assignment-results.csv`
5. Prints a summary — Assigned, Already Exists, Skipped, Failed counts

The script is fully idempotent — safe to re-run at any time without creating duplicate assignments.

### Modules Used

Az module only. No Microsoft Graph required for Azure RBAC assignments.

```powershell
Connect-AzAccount -TenantId "401bd5c7-e8b2-4bee-83f6-abf0bad3b953"
```

---

## Verification

After running the script, assignments were verified in the Azure Portal under **Access Control (IAM) → Role Assignments** at two levels:

**Subscription level (CloudSchool-Prod-Subscription):**
- Akshay Kattoth → Owner → This resource
- Mr. Vishnu Prakash → Owner → This resource
- GRP-Staff-Management → Reader → This resource

**Resource group level (RG-Compute-Prod):**
- GRP-Staff-IT → Contributor → This resource (directly assigned)
- GRP-Staff-Management → Reader → Subscription (Inherited)
- GRP-Staff-Operations → Reader → This resource (directly assigned)
- Akshay Kattoth → Owner → Subscription (Inherited)
- Mr. Vishnu Prakash → Owner → Subscription (Inherited)

The Inherited entries confirmed that subscription-level assignments flow down automatically — no additional assignments needed at the RG level for those principals.

---

## Key Learnings

- **Contributor can delete resources** — it is not a safe or read-only role. It has full create, modify, and delete rights on resources. Only role assignment capability is missing.
- **Owner at subscription is the most powerful assignment** — keep it to minimum named individuals, never a broad group.
- **Inheritance works downward only** — a permission at resource group level does not propagate up to the subscription.
- **Role assignments are additive** — if a user has Reader at subscription and Contributor on one RG, both apply. There is no conflict, the higher permission wins at the RG level.
- **No deny assignments in standard RBAC** — there is no way to explicitly block access using standard role assignments. Deny assignments exist as an advanced feature but are rarely used.
- **Azure RBAC and Entra ID roles are completely separate** — having Owner in Azure gives no rights in Entra ID, and being a Global Admin in Entra gives no rights over Azure resources unless explicitly assigned via RBAC.
- **Always assign to groups, not users** — except for sensitive roles like Owner where explicit named accountability is required.
- **`$PSScriptRoot` makes scripts location-independent** — always use it for relative paths instead of hardcoding directory names.
