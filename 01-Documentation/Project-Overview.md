# Project Overview – CloudSchool

## 📌 Introduction
CloudSchool is a simulated school environment built to practice real-world cloud administration tasks using Microsoft 365, Entra ID, and Azure.

In this project, I take on the role of a Cloud Administrator responsible for setting up, managing, and maintaining the organization's cloud infrastructure.

The focus is not just on learning concepts, but on applying them practically with proper structure, automation, and documentation.

---

## 🎯 Objective
The main objective of this project is to:

- Build a structured identity environment for a school
- Automate user and group management using PowerShell
- Apply Microsoft 365 and Entra ID administration concepts
- Gradually implement Azure (AZ-104) infrastructure components
- Maintain proper documentation similar to a real-world environment

---

## 🏫 Environment Details

### Organization Name
CloudSchool

### Domain
cloudschool.ink

### Users
- Students: 500
- Staff: 55

### Structure
- Grades: 1 to 6
- Divisions: A, B, C

---

## 🧩 Design Approach

The environment is designed with a focus on:

### 1. Scalability
- Group structure allows easy expansion (more grades/divisions can be added)

### 2. Automation
- Student provisioning (idempotent CSV-driven automation)
- Staff provisioning (create/update/skip with attribute mapping and extension attributes)

### 3. Standardization
- Consistent naming conventions for users and groups
- Attribute-based classification for easy filtering

### 4. Manageability
- Clear separation between students and staff
- Logical grouping based on grade and division

---

## Staff Provisioning

The staff provisioning phase was rebuilt into a structured, reusable workflow instead of one-time scripts.

The implementation includes:

1. Cleaning exported identity data
2. Maintaining separate role and assignment mapping
3. Merging datasets into a final source-of-truth CSV
4. Running an idempotent provisioning script

The workflow uses:

- `08-build-staff-csv.ps1`
- `09-merge-staff-csv.ps1`
- `03-create-staff.ps1`

This approach ensures:

- new users are created
- existing users are updated only when changes are detected
- already correct users are skipped
- extension attributes are applied consistently

---

## 🛠 Technologies Used

- Microsoft Entra ID (Azure AD)
- Microsoft 365 Admin Center
- PowerShell (Microsoft Graph module, Az module)
- GitHub (for version control and documentation)

---

## 📋 Task → Script → Documentation Mapping

Script and documentation filenames are not required to match numerically — this table is the single source of truth for how they relate. If a task, script, or doc is renamed or added, update this table only; do not duplicate it elsewhere.

| Task | Description | Script(s) | Documentation |
|---|---|---|---|
| T1 | Custom domain setup (cloudschool.ink) | — | *(covered in this overview)* |
| T2 | Student provisioning (500 users) | `02-create-students.ps1` | `Student-Provisioning.md` |
| T3 | Staff provisioning (~55 users) | `03-create-staff.ps1`, `08-build-staff-csv.ps1`, `09-merge-staff-csv.ps1` | `Staff-Provisioning.md` |
| T4 | Group creation (49 groups) | `04-Create-Groups.ps1`, `05-Assign-Users-To-Groups.ps1` | `Group-Design-and-Implementation.md` |
| T5 | Attribute standardization | — | `Attribute-Standardization.md` |
| T6 | Administrative Units (28 AUs) | `06-create-administrative-units.ps1` | `Administrative-Units.md` |
| T7 | Role delegation (scoped Helpdesk Admin) | `13-role-delegation.ps1` | `Role-Delegation.md` |
| T8 | Azure RBAC (11 assignments) | `14-assign-rbac-roles.ps1` | `RBAC-Design-and-Implementation.md` |
| T9 | License assignment (WhatIf, group-based) | `15-assign-licenses.ps1` | `License-Assignment-Design-and-Implementation.md` |
| T10 | Storage Account | `16-create-storage-account.ps1` | `Storage-Account-Design-and-Implementation.md` |
| — | Graph connection (shared utility) | `01-connect-mggraph.ps1` | `PowerShell-Automation-Guide.md` |
| — | Azure connection (shared utility) | `10-connect-AzAccount.ps1` | `PowerShell-Automation-Guide.md` |
| — | Resource Group creation (infra foundation) | `07-create-resource-groups.ps1` | `Resource-Group-Design.md` |
| — | VNet + subnet creation (infra foundation) | `11-create-vnets-and-subnets.ps1` | `VNet-Design-and-Implementation.md` |
| — | Azure Policy / governance | `12-assign-allowed-location-policy.ps1` | `Azure-Policy-Governance.md` |
| — | Fixes and lessons learned across tasks | — | `Troubleshooting-and-Fixes.md` |

**Remaining tasks (T11–T30)** are tracked in the main `README.md` roadmap table and do not yet have scripts or documentation.

---

## 📈 Current Status

**Completed (T1–T10):**

- Custom domain setup (cloudschool.ink)
- Student provisioning (500 users)
- Staff provisioning (~55 users)
- Group creation (49 groups)
- Attribute standardization (employeeType, extension attributes)
- Administrative Units (28 AUs)
- Role delegation (scoped Helpdesk Administrator via role-assignable groups)
- Azure RBAC (11 role assignments across subscription and resource groups)
- License assignment (group-based, WhatIf simulation — Education SKUs)
- Storage Account (`stcloudschoolprod001`, Standard GPv2, LRS, Hot tier)

**In progress:** none currently — T10 is complete; T11 (Blob Storage) is next.

---

## 🔜 Next Steps

Remaining roadmap (T11–T30), grouped by AZ-104 domain:

- **Storage (T11–T14):** Blob Storage, File Share, Access Tiers, Storage Access (private endpoints)
- **Compute (T15–T20):** Windows VM, Linux VM, VM Configuration, Azure Bastion, VM Extensions, Containers
- **Networking (T21–T25):** NSGs, VNet Peering, Private DNS, Azure Bastion, Load Balancer
- **Monitoring (T26–T30):** Azure Monitor, Log Analytics, Diagnostics Settings, Cost Management, Azure Backup

See the main `README.md` for the full roadmap table and target timeline.

---

## 📌 Summary

This project represents a practical, hands-on approach to learning cloud administration by building and managing a structured environment from scratch.

It is designed to simulate real-world responsibilities of a Cloud Administrator and to build skills relevant for roles requiring Azure and Microsoft 365 expertise.
