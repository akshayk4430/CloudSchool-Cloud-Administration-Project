# CloudSchool – Cloud Administration Project (AZ-104)

## 📌 Overview
CloudSchool is a simulated real-world school cloud environment where I act as the assigned **Cloud Administrator** responsible for designing, deploying, and managing the complete IT infrastructure.

This project is built to apply practical skills from **Microsoft Azure AZ-104** and real Microsoft 365 administration practices.  
The goal is to create a fully documented and automated cloud setup that reflects how a real organization would be managed.

---

## 🎯 Project Goals

- Build a realistic school tenant in Microsoft 365 + Entra ID
- Implement structured identity management for students and staff
- Automate provisioning using CSV-driven PowerShell workflows
- Build idempotent scripts supporting create, update, and skip logic
- Apply attribute-based identity classification (employeeType, extension attributes)
- Design scalable group structures for grade and department management
- Implement administrative units for organizational control
- Maintain production-style documentation and version control using GitHub
- Create an interview-ready cloud administration portfolio project

---

## 🏫 Organization Structure (CloudSchool)
This project includes:
- **Students:** 500 accounts
- **Staff:** 55 accounts
- **Grades:** 1 to 6
- **Divisions:** A, B, C

---

## ✅ Completed Work (Current Progress)


### 1. Custom Domain Setup
- Domain configured and verified: `cloudschool.ink`
- User Principal Names (UPN) standardized to use the custom domain

### 2. Identity Provisioning (Students & Staff)
- Provisioning is implemented using CSV-driven PowerShell automation with idempotent create/update/skip logic.

#### Student Provisioning
- 500 student accounts created using structured CSV input
- Script supports create, update, and skip operations
- Grade and division are applied using extension attributes

#### Staff Provisioning
Staff provisioning was redesigned into a structured workflow:

- Data cleanup and normalization (`08-build-staff-csv.ps1`)
- Attribute mapping (`staff-attributes.csv`)
- Dataset merge (`09-merge-staff-csv.ps1`)
- Final provisioning (`03-create-staff.ps1`)

The staff provisioning script:
- creates missing users
- updates only changed fields
- applies extension attributes (Role and Assignment)
- skips already-correct users on rerun

This ensures safe, repeatable automation aligned with real-world practices.

- exports provisioning results for validation (`staff-provisioning-results.csv`)

### 3. Group Design and Implementation

Group naming is standardized using:

GRP-<EmployeeType>-<Logical Unit>

#### Student Groups

Student groups are based on grade and division:

**Grade-level groups**
- GRP-Student-Grade-01
- GRP-Student-Grade-02
- GRP-Student-Grade-03
- GRP-Student-Grade-04
- GRP-Student-Grade-05
- GRP-Student-Grade-06

**Division-level groups**
- GRP-Student-Grade-01-A, GRP-Student-Grade-01-B, GRP-Student-Grade-01-C  
- GRP-Student-Grade-02-A, GRP-Student-Grade-02-B, GRP-Student-Grade-02-C  
- ...  
- GRP-Student-Grade-06-A, GRP-Student-Grade-06-B, GRP-Student-Grade-06-C  

Total student groups: **24**

#### Staff Groups

- GRP-Staff-All (contains all staff users)
- Department-based groups:
  - GRP-Staff-IT
  - GRP-Staff-Operations
  - GRP-Staff-Academics
  - GRP-Staff-Student_Support
  - etc.

Note:
Department values are standardized to match group naming.  
Spaces are replaced with underscores (e.g., Student Support → Student_Support).

### 4. Attribute Standardization
To maintain identity structure and easy filtering:

| Attribute | Usage |
|----------|--------|
| employeeType | Staff / student |
| extensionAttribute1 | Student: Grade / Staff: Role |
| extensionAttribute2 | Student: Division / Staff: Assignment |

employeeType values:
- Staff = `Staff`
- Student = `Student`
---
## ⚙️ Provisioning Model

The provisioning system is designed as a reusable pipeline:

- CSV as source of truth
- Separation of identity data and business logic
- Dynamic comparison of existing users
- Update only when changes are detected
- Idempotent script execution (safe re-runs)
- Minimizes unnecessary Microsoft Graph API calls

This approach reduces unnecessary API calls and ensures consistency across large datasets.


## 🛠 Tools Used
- Microsoft Entra ID (Azure AD)
- Microsoft 365 Admin Center
- PowerShell
- Microsoft Graph PowerShell Module
- GitHub (Documentation + Automation Storage)

---

## 📂 Repository Structure
```plaintext
01-Documentation/     -> Step-by-step implementation notes
02-Scripts/           -> PowerShell scripts used for automation
03-CSV-Templates/     -> Input templates used for bulk provisioning
04-Screenshots/       -> Portal screenshots for proof and reference
05-Outputs/           -> Export reports and validation results
```


