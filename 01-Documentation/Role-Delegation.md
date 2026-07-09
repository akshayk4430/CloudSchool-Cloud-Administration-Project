# 03 - Role Delegation

## What is Role Delegation

Role delegation in Microsoft Entra ID is the process of assigning built-in directory roles to users or groups — but scoped to a specific Administrative Unit instead of the entire tenant.

This means the person receiving the role can only perform those actions within the boundary of that AU. Outside that AU, they have no elevated permissions at all.

In CloudSchool, role delegation was implemented so that Grade Coordinators and Class Teachers can manage student accounts within their own scope, without ever touching students from other grades or divisions — and without any access to staff accounts.

---

## Why Role-Assignable Groups Instead of Direct Assignment

The role is not assigned directly to the staff member's user account. Instead, a dedicated security group is created for each delegation, and the role is assigned to that group.

This was a deliberate design decision for two reasons:

1. **Maintainability** — If a Grade Coordinator changes (e.g., a new teacher takes over), only the group membership needs to be updated in the CSV. The role assignment itself stays untouched. Without this, you would need to remove and recreate the role assignment every time a staff member changes.

2. **Consistency** — All delegation is driven from `role-delegation.csv`. The script reads the CSV, creates or updates groups, syncs members, and assigns roles. No manual changes needed in the portal.

This pattern — role-assignable groups over direct assignment — is a recommended practice in real-world Entra ID environments.

---

## Design

### Roles Assigned

| Staff Role | Entra Role | Scope |
|---|---|---|
| Grade Coordinator | Helpdesk Administrator | Grade-level AU (e.g., `AU-CloudSchool-Grade-01`) |
| Class Teacher | Helpdesk Administrator | Division-level AU (e.g., `AU-CloudSchool-Grade-01-A`) |

### What Helpdesk Administrator Can Do

Within their scoped AU, the assigned staff member can:
- Reset passwords for students
- Manage basic account properties

They **cannot**:
- Access or modify any user outside their AU
- Access staff accounts (staff are not members of any grade or division AU)
- Perform any tenant-wide admin actions

### Group Naming Convention

Each delegation group follows this naming pattern:

- Grade level: `GRP-Delegate-HelpdeskAdmin-Grade01-Coordinator`
- Division level: `GRP-Delegate-HelpdeskAdmin-Grade01-A-Coordinator`

These groups are created as **role-assignable security groups** — a special group type in Entra ID that is required before a group can be used in a role assignment. This flag can only be set at group creation time and cannot be changed afterwards.

---

## Implementation

The entire process is automated using `13-role-delegation.ps1`, driven by `03-CSV-Templates/role-delegation.csv`.

### CSV Structure

| Column | Purpose |
|---|---|
| `GroupName` | Name of the role-assignable group to create |
| `GroupDescription` | Description for the group |
| `AUName` | The Administrative Unit this delegation is scoped to |
| `RoleName` | The Entra role to assign (`Helpdesk Administrator`) |
| `MemberUPN` | UPN of the staff member to add to the group |

### Script Logic (in order)

1. Validates the CSV exists and contains all required columns
2. Fetches all existing AUs, groups, and users upfront into memory — avoids repeated API calls per row
3. Groups CSV rows by `GroupName` — handles cases where a group has multiple members
4. For each group:
   - Checks if the target AU exists — skips and logs a warning if not
   - Creates the group if it does not exist (with `IsAssignableToRole: true`)
   - Syncs membership — adds users in the CSV but not in the group, removes users in the group but not in the CSV
   - Assigns the Helpdesk Administrator role scoped to the AU — skips if the assignment already exists
5. Exports results to `05-Outputs/role-delegation-results.csv`

The script is fully idempotent — safe to re-run at any time without creating duplicate groups or duplicate role assignments.

### Graph Scopes Required

```
Connect-MgGraph -Scopes "AdministrativeUnit.ReadWrite.All","User.Read.All","Directory.Read.All","Group.ReadWrite.All","RoleManagement.ReadWrite.Directory"
```

`AdministrativeUnit.ReadWrite.All` must be explicitly included. Omitting it causes a 403 Forbidden error even when other scopes are present.

---

## Scale

| Delegation Type | Count |
|---|---|
| Grade-level role-assignable groups | 6 |
| Division-level role-assignable groups | 18 |
| Total groups created | 24 |
| Total scoped role assignments | 24 |

---

## Key Learnings

- **AUs are scope boundaries, not permission grants.** An AU by itself does nothing. Permissions come from a role assignment that is scoped to that AU. If no role is assigned, the AU has no effect on access.
- **`IsAssignableToRole` cannot be changed after creation.** This flag must be set when the group is first created. If you forget and create a regular group, you have to delete it and recreate it.
- **`AdministrativeUnit.ReadWrite.All` is easy to miss.** It is not implied by other scopes and must be explicitly added when connecting to Graph.
- **Role-assignable groups are a premium feature.** They require Microsoft Entra ID P1 or P2 licensing in production environments.
- **`employeeType` is not filterable via Graph API.** The script fetches all users and handles filtering logic in PowerShell rather than relying on Graph-side filters.
