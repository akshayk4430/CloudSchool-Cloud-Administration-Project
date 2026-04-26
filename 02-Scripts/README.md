# ⚙️ Scripts – CloudSchool Automation

## 📌 Overview

This folder contains all PowerShell scripts used to automate identity provisioning and management in the CloudSchool environment.

The scripts follow a structured, CSV-driven approach with idempotent logic to support:

* Create
* Update
* Skip
* Safe re-runs without duplication

---

## 🧱 Provisioning Model

The automation is built as a pipeline:

1. Prepare identity data (CSV)
2. Maintain attribute mapping separately
3. Merge datasets into a final source-of-truth file
4. Run provisioning scripts with comparison logic

---

## 🔄 Execution Order

### 🔹 Step 1 – Connect to Microsoft Graph

```powershell
01-connect-mggraph.ps1
```

* Authenticates to Microsoft Graph
* Ensure correct permissions before execution

---

### 🔹 Step 2 – Student Provisioning

```powershell
02-create-students.ps1
```

* Reads from `students.csv`
* Creates new users
* Updates existing users if changes detected
* Applies:

  * Grade (`ExtensionAttribute1`)
  * Division (`ExtensionAttribute2`)
* Skips users already in correct state

---

### 🔹 Step 3 – Staff Data Preparation

```powershell
08-build-staff-csv.ps1
```

* Cleans raw export data
* Fixes missing names
* Standardizes attributes
* Output: `staff.csv`

---

### 🔹 Step 4 – Staff Attribute Merge

```powershell
09-merge-staff-csv.ps1
```

* Merges:

  * `staff.csv`
  * `staff-attributes.csv`
* Output: `staff-final.csv`

---

### 🔹 Step 5 – Staff Provisioning

```powershell
03-create-staff.ps1
```

* Reads from `staff-final.csv`
* Creates missing users
* Updates only changed fields
* Applies:

  * Role (`ExtensionAttribute1`)
  * Assignment (`ExtensionAttribute2`)
* Skips already-correct users
* Outputs: `staff-provisioning-results.csv`

---

### 🔹 Step 6 – Group Creation

```powershell
04-Create-Groups.ps1
```

* Reads from `groups-required.csv`
* Creates missing groups
* Skips existing groups
* Idempotent design

---

### 🔹 Step 7 – Group Assignment

```powershell
05-Assign-Users-To-Groups.ps1
```

* Assigns users based on attributes

Student logic:

* Grade → `GRP-Student-Grade-*`
* Division → `GRP-Student-Grade-*-*`
* License → `GRP-M365-License-Students`
* Policy → `GRP-Policy-CA-Students`

Staff logic:

* All → `GRP-Staff-All`
* Department → `GRP-Staff-*`
* License → `GRP-M365-License-Staff`
* Policy → `GRP-Policy-CA-Staff`

Role logic:

* ExtensionAttribute1 → Role groups
* Department → Teachers / IT Admins

---

### 🔹 Step 8 – Administrative Units

```powershell
06-create-administrative-units.ps1
```

* Creates Administrative Units
* Supports delegation and RBAC

---

## 📊 Key Features

* CSV-driven identity management
* Idempotent provisioning logic
* Dynamic comparison before update
* Extension attribute classification
* Separation of identity and logic
* Optimized Microsoft Graph usage

---

## ⚠️ Notes

* Scripts are safe for re-execution
* Always test with small dataset
* CSV files act as source of truth
