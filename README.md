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

### 3. Group Management (Production-Grade Automation)

Group lifecycle management is implemented using a structured, automated approach.

#### Group Naming Standard

All groups follow:

`GRP-<Type>-<Logical Unit>`
---

### Group Categories

#### 1. Organizational Groups

Based on structure:

- Students → Grade and Division  
- Staff → Department  

Examples:

`- GRP-Student-Grade-01`  
`- GRP-Student-Grade-01-A`  
`- GRP-Staff-IT  `
`- GRP-Staff-Operations ` 

---

#### 2. Role-Based Groups

Based on staff responsibilities:

- GRP-Role-Teachers  
- GRP-Role-ClassTeachers  
- GRP-Role-GradeCoordinators  
- GRP-Role-DeptHeads  
- GRP-Role-Principal  
- GRP-Role-ITAdmins  

---

#### 3. Service / Policy Groups

Used for Microsoft 365 and security targeting:

- GRP-M365-License-Students  
- GRP-M365-License-Staff  
- GRP-Policy-CA-Students  
- GRP-Policy-CA-Staff  

---

### Group Creation (Automation)
Source of truth: 03-CSV-Templates/groups-required.csv
Script:

02-Scripts/04-Create-Groups.ps1

Features:

- CSV-driven source of truth (`groups-required.csv`)
- Creates missing groups
- Skips existing groups
- Idempotent (safe to re-run)
- Logs results to CSV

Total managed groups: **49**

---

### Group Assignment (Automation)

Script:

02-Scripts/05-Assign-Users-To-Groups.ps1

#### Student Assignment

- Grade → GRP-Student-Grade-*  
- Division → GRP-Student-Grade-*-*  
- License → GRP-M365-License-Students  
- Policy → GRP-Policy-CA-Students  

#### Staff Assignment

- All staff → GRP-Staff-All  
- Department → GRP-Staff-*  
- License → GRP-M365-License-Staff  
- Policy → GRP-Policy-CA-Staff  

#### Role-Based Assignment

- ExtensionAttribute1 → Role groups  
- Department → Teachers / IT Admins  

---

### Design Principles

- Attribute-driven identity model  
- No manual mapping logic required  
- Separation of structure, role, and policy groups  
- Idempotent automation (Create / Add / Skip / Failed)  
- Optimized Microsoft Graph usage (caching and minimal API calls)  

This approach reflects real-world enterprise identity and access management practices.

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


