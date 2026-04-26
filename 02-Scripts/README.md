# ⚙️ Scripts – CloudSchool Automation

## 📌 Overview

This folder contains all PowerShell scripts used to automate identity provisioning, group creation, group assignment, and administrative unit management in the CloudSchool environment.

The scripts follow a structured, CSV-driven approach with idempotent logic to support:

* Create
* Update
* Skip
* Safe re-runs without duplication

---

## 🧱 Automation Model

The automation is built as a pipeline:

1. Connect to Microsoft Graph
2. Prepare identity data using CSV files
3. Provision student and staff users
4. Create required groups from CSV source of truth
5. Assign users to groups based on attributes
6. Create administrative units for future delegation/RBAC

---

## 🔄 Execution Order

### Step 1 – Connect to Microsoft Graph

```powershell
01-connect-mggraph.ps1
```

* Authenticates to Microsoft Graph
* Required before running other scripts
* Requires appropriate Graph permissions such as user, group, and directory read/write scopes

---

### Step 2 – Student Provisioning

```powershell
02-create-students.ps1
```

* Reads from `students.csv`
* Creates new student users
* Updates existing users if changes are detected
* Applies:

  * `EmployeeType`
  * Grade using `ExtensionAttribute1`
  * Division using `ExtensionAttribute2`
* Skips users already in the correct state

---

### Step 3 – Staff Provisioning

```powershell
03-create-staff.ps1
```

* Reads from `staff-final.csv`
* Creates missing staff users
* Updates existing users only when changes are detected
* Applies:

  * `Department`
  * Role using `ExtensionAttribute1`
  * Assignment using `ExtensionAttribute2`
* Skips users already in the correct state
* Exports results to `staff-provisioning-results.csv`

---

### Step 4 – Group Creation

```powershell
04-Create-Groups.ps1
```

* Reads from `groups-required.csv`
* Creates missing Entra ID groups
* Skips existing groups
* Uses CSV as the group source of truth
* Supports organizational, role-based, and service/policy groups
* Exports results to `group-creation-results.csv`

---

### Step 5 – Group Assignment

```powershell
05-Assign-Users-To-Groups.ps1
```

* Assigns users to groups based on Entra ID attributes
* Uses cached groups and membership checks to reduce unnecessary Graph calls
* Adds missing memberships
* Skips existing memberships
* Exports results to `group-assignment-results.csv`

Student assignment logic:

* Grade → `GRP-Student-Grade-*`
* Division → `GRP-Student-Grade-*-*`
* License → `GRP-M365-License-Students`
* Policy → `GRP-Policy-CA-Students`

Staff assignment logic:

* All staff → `GRP-Staff-All`
* Department → `GRP-Staff-*`
* License → `GRP-M365-License-Staff`
* Policy → `GRP-Policy-CA-Staff`

Role assignment logic:

* `ExtensionAttribute1` → Role groups
* `Department = Academics` → `GRP-Role-Teachers`
* `Department = IT` → `GRP-Role-ITAdmins`

---

### Step 6 – Administrative Units

```powershell
06-create-administrative-units.ps1
```

* Creates Administrative Units
* Supports future delegation and RBAC scenarios
* Groups users logically for administrative control

---

## Supporting Scripts

### Staff CSV Preparation

```powershell
08-build-staff-csv.ps1
09-merge-staff-csv.ps1
```

These scripts were used during the staff provisioning phase to:

* Clean raw staff export data
* Normalize attributes
* Merge identity data with attribute mapping
* Produce `staff-final.csv`

---

## 📊 Key Features

* CSV-driven identity and group management
* Idempotent provisioning logic
* Create / Update / Skip / Failed result handling
* Attribute-based group assignment
* Group source of truth using `groups-required.csv`
* Reduced unnecessary Microsoft Graph API calls through caching
* Output CSV files for validation and troubleshooting

---

## ⚠️ Notes

* Scripts are designed for safe re-execution
* Always test with a small dataset before full execution
* CSV files act as the source of truth
* Group creation and group assignment are intentionally separated for maintainability
