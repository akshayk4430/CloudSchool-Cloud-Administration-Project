# CloudSchool – Cloud Administration Project (AZ-104)

## 📌 Overview

CloudSchool is a simulated real-world school cloud environment where I act as the assigned **Cloud Administrator** responsible for designing, deploying, and managing the complete IT infrastructure.

This project is built to apply practical skills from **Microsoft Azure AZ-104** and real Microsoft 365 administration practices.
The goal is to create a fully documented and automated cloud setup that reflects how a real organization would be managed.

---

## 🎯 Project Goals

* Build a realistic school tenant in Microsoft 365 + Entra ID
* Implement structured identity management for students and staff
* Automate provisioning using CSV-driven PowerShell workflows
* Build idempotent scripts supporting create, update, and skip logic
* Apply attribute-based identity classification (employeeType, extension attributes)
* Design scalable group structures for grade and department management
* Implement administrative units for organizational control
* Maintain production-style documentation and version control using GitHub
* Create an interview-ready cloud administration portfolio project

---

## 🏫 Organization Structure (CloudSchool)

* **Students:** 500 accounts
* **Staff:** 55 accounts
* **Grades:** 1 to 6
* **Divisions:** A, B, C

---

## ✅ Completed Work (Current Progress)

### 1. Custom Domain Setup

* Domain configured and verified: `cloudschool.ink`
* User Principal Names (UPN) standardized to use the custom domain

---

### 2. Identity Provisioning (Students & Staff)

Provisioning is implemented using CSV-driven PowerShell automation with idempotent create/update/skip logic.

#### Student Provisioning

* 500 student accounts created using structured CSV input
* Script supports create, update, and skip operations
* Grade and division applied using extension attributes

#### Staff Provisioning

* Data cleanup and normalization (`08-build-staff-csv.ps1`)
* Attribute mapping (`staff-attributes.csv`)
* Dataset merge (`09-merge-staff-csv.ps1`)
* Final provisioning (`03-create-staff.ps1`)

Features:

* Creates missing users
* Updates only changed fields
* Applies role and assignment attributes
* Skips already-correct users

Output:

* `staff-provisioning-results.csv`

---

### 3. Group Management (Production-Grade Automation)

Group lifecycle management is implemented using a structured, automated approach.

#### Group Naming Standard

All groups follow:

`GRP-<Type>-<Logical Unit>`

---

### Group Categories

#### 1. Organizational Groups

* Students → Grade and Division
* Staff → Department

Examples:

* `GRP-Student-Grade-01`
* `GRP-Student-Grade-01-A`
* `GRP-Staff-IT`
* `GRP-Staff-Operations`

---

#### 2. Role-Based Groups

* `GRP-Role-Teachers`
* `GRP-Role-ClassTeachers`
* `GRP-Role-GradeCoordinators`
* `GRP-Role-DeptHeads`
* `GRP-Role-Principal`
* `GRP-Role-ITAdmins`

---

#### 3. Service / Policy Groups

* `GRP-M365-License-Students`
* `GRP-M365-License-Staff`
* `GRP-Policy-CA-Students`
* `GRP-Policy-CA-Staff`

---

### Group Creation (Automation)

Source of truth: `03-CSV-Templates/groups-required.csv`

Script: `02-Scripts/04-Create-Groups.ps1`

Features:

* CSV-driven design
* Creates missing groups
* Skips existing groups
* Idempotent execution
* Logs results

Total managed groups: **49**

---

### Group Assignment (Automation)

Script: `02-Scripts/05-Assign-Users-To-Groups.ps1`

#### Student Assignment

* Grade → `GRP-Student-Grade-*`
* Division → `GRP-Student-Grade-*-*`
* License → `GRP-M365-License-Students`
* Policy → `GRP-Policy-CA-Students`

---

#### Staff Assignment

* All staff → `GRP-Staff-All`
* Department → `GRP-Staff-*`
* License → `GRP-M365-License-Staff`
* Policy → `GRP-Policy-CA-Staff`

---

#### Role-Based Assignment

* ExtensionAttribute1 → Role groups
* Department → Teachers / IT Admins

---

### Design Principles

* Attribute-driven identity model
* No manual mapping logic
* Separation of structure, role, and policy groups
* Idempotent automation (Create / Add / Skip / Failed)
* Optimized Microsoft Graph usage

---

### 4. Attribute Standardization

| Attribute           | Usage                                 |
| ------------------- | ------------------------------------- |
| employeeType        | Staff / Student                       |
| extensionAttribute1 | Student: Grade / Staff: Role          |
| extensionAttribute2 | Student: Division / Staff: Assignment |

Values:

* Staff = `Staff`
* Student = `Student`

---

## ⚙️ Provisioning Model

* CSV as source of truth
* Separation of identity and logic
* Dynamic comparison before update
* Idempotent execution
* Minimal API usage

---

## 🛠 Tools Used

* Microsoft Entra ID (Azure AD)
* Microsoft 365 Admin Center
* PowerShell
* Microsoft Graph PowerShell Module
* GitHub

---

## 📂 Repository Structure

```plaintext
01-Documentation/     -> Documentation
02-Scripts/           -> PowerShell scripts
03-CSV-Templates/     -> Input templates
04-Screenshots/       -> Evidence
05-Outputs/           -> Results and logs
```
