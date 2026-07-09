# CloudSchool – Cloud Administration Project (AZ-104)

## 📌 Overview

CloudSchool is a simulated real-world school cloud environment where I act as the assigned **Cloud Administrator** responsible for designing, deploying, and managing the complete IT infrastructure.

This project is built to apply practical skills from **Microsoft Azure AZ-104** and real Microsoft 365 administration practices.
The goal is to create a fully documented and automated cloud setup that reflects how a real organization would be managed.

---

## 📊 Project Status

| Stage                 | Status      |
|----------------------|-------------|
| Identity             | Completed   |
| Groups               | Completed   |
| Administrative Units | Completed   |
| Resource Groups      | Completed   |
| Networking (VNet)    | Completed   |
| Governance (Policy)  | Completed   |

---

## 🎯 Project Goals

* Build a realistic school tenant in Microsoft 365 + Entra ID
* Implement structured identity management for students and staff
* Automate provisioning using CSV-driven PowerShell workflows
* Build idempotent scripts supporting create, update, and skip logic
* Apply attribute-based identity classification (employeeType, extension attributes)
* Design scalable group structures for grade and department management
* Prepare administrative units for organizational control and rebuild them in the current tenant
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

* Generated locally (not stored in repository)

---

### 3. Group Management (Production-Grade Automation)

#### Group Naming Standard

All groups follow:

`GRP-<Type>-<Logical Unit>`

---

#### Group Categories

##### Organizational Groups

* Students → Grade and Division
* Staff → Department

Examples:

* `GRP-Student-Grade-01`
* `GRP-Student-Grade-01-A`
* `GRP-Staff-IT`
* `GRP-Staff-Operations`

---

##### Role-Based Groups

* `GRP-Role-Teachers`
* `GRP-Role-ClassTeachers`
* `GRP-Role-GradeCoordinators`
* `GRP-Role-DeptHeads`
* `GRP-Role-Principal`
* `GRP-Role-ITAdmins`

---

##### Service / Policy Groups

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

Total managed groups: **49**

---

### Group Assignment (Automation)

Script: `02-Scripts/05-Assign-Users-To-Groups.ps1`

#### Student Assignment

* Grade → `GRP-Student-Grade-*`
* Division → `GRP-Student-Grade-*-*`
* License → `GRP-M365-License-Students`
* Policy → `GRP-Policy-CA-Students`

#### Staff Assignment

* All staff → `GRP-Staff-All`
* Department → `GRP-Staff-*`
* License → `GRP-M365-License-Staff`
* Policy → `GRP-Policy-CA-Staff`

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
|-------------------|-------------------------------------|
| employeeType        | Staff / Student                     |
| extensionAttribute1 | Student: Grade / Staff: Role        |
| extensionAttribute2 | Student: Division / Staff: Assignment |

Values:

* Staff = `Staff`
* Student = `Student`

---

### 5. Azure Infrastructure (AZ-104 Progress)

#### Subscription

* Azure subscription created and configured
* Renamed to: `CloudSchool-Prod-Subscription`

---

#### Resource Groups

* Structured resource groups implemented using CSV-driven automation
* Script: `02-Scripts/07-create-resource-groups.ps1`
* Environment-based segmentation applied

---

#### Virtual Network (VNet)

Production VNet deployed:

* Name: `VNet-CloudSchool-Prod`
* Address Space: `10.10.0.0/16`

Subnets:

* `SNet-Management-Prod` → `10.10.1.0/24`
* `SNet-Workload-Prod` → `10.10.2.0/24`
* `SNet-PrivateEndpoint-Prod` → `10.10.3.0/24`

Automation:

- CSV-driven VNet and subnet configuration
- Script: `02-Scripts/11-create-vnets-and-subnets.ps1`
- Idempotent execution (Create / Add / Skip)

---

#### Governance / Azure Policy

Azure Policy governance implemented using the built-in **Allowed locations** policy.

Policy assignment:

* Name: `audit-allowed-locations-rg-compute-dev`
* Scope: `RG-Compute-Dev`
* Allowed location: `uaenorth`
* Effect: `Audit`

Automation:

- Script: `02-Scripts/12-assign-allowed-location-policy.ps1`
- Documentation: `01-Documentation/Azure-Policy-Governance.md`
- Idempotent execution
- Supports `-WhatIf`
- Checks for existing assignment before creation

#### Design Principles

* Environment isolation (Prod vs Dev)
* Subnet-based workload segmentation
* Azure-native architecture aligned with AZ-104

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
* Azure Portal
* Azure PowerShell (Az Module)
* PowerShell
* Microsoft Graph PowerShell Module
* Git & GitHub (Feature Branch Workflow)

---

## 📂 Repository Structure

```plaintext
01-Documentation/     -> Documentation
02-Scripts/           -> PowerShell scripts
03-CSV-Templates/     -> Input templates
04-Screenshots/       -> Evidence
05-Outputs/           -> Generated results (ignored in Git)
06-Notes/             -> Learning notes

```
