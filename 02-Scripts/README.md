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
* Ensure correct permissions and test in a non-production environment before full execution

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

  * identity data (`staff.csv`)
  * attribute mapping (`staff-attributes.csv`)
* Output: `staff-final.csv`

---

### 🔹 Step 5 – Staff Provisioning

```powershell
03-create-staff.ps1
```

* Reads from `staff-final.csv`
* Creates missing users
* Compares existing users
* Updates only changed fields
* Applies:

  * `ExtensionAttribute1` (Role)
  * `ExtensionAttribute2` (Assignment)
* Skips already-correct users
* Exports results to `staff-provisioning-results.csv`

---

### 🔹 Step 6 – Group Assignment

```powershell
04-assign-groups.ps1
```

* Assigns users to groups based on attributes
* Students → Grade/Division groups
* Staff → Department groups

---

### 🔹 Step 7 – Administrative Units

```powershell
05-create-administrative-units.ps1
```

* Creates Administrative Units (AUs)
* Supports logical delegation and segmentation

---

## 📊 Key Features

* CSV-driven identity management
* Idempotent provisioning logic
* Dynamic comparison before update
* Extension attribute handling for classification
* Separation of identity and business logic
* Reduced unnecessary Microsoft Graph API calls

---

## ⚠️ Notes

* Scripts are designed for safe re-execution
* Always test with a small dataset before full run
* CSV files act as the source of truth
