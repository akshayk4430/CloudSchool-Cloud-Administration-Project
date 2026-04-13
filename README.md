# CloudSchool – Cloud Administration Project (AZ-104)

## 📌 Overview
CloudSchool is a simulated real-world school cloud environment where I act as the assigned **Cloud Administrator** responsible for designing, deploying, and managing the complete IT infrastructure.

This project is built to apply practical skills from **Microsoft Azure AZ-104** and real Microsoft 365 administration practices.  
The goal is to create a fully documented and automated cloud setup that reflects how a real organization would be managed.

---

## 🎯 Project Goals
- Build a realistic school tenant in **Microsoft 365 + Entra ID**
- Automate bulk user and group provisioning using **PowerShell**
- Implement structured identity and access management (IAM)
- Apply AZ-104 infrastructure concepts (networking, compute, storage, monitoring)
- Build security baselines (MFA, Conditional Access, RBAC)
- Maintain full documentation as a real cloud admin would do
- Create a GitHub portfolio project for interview readiness

---

## 🏫 Organization Structure (CloudSchool)
This project includes:
- **Students:** 500 accounts
- **Staff:** 50 accounts
- **Grades:** 1 to 6
- **Divisions:** A, B, C

---

## ✅ Completed Work (Current Progress)

### 1. Custom Domain Setup
- Domain configured and verified: `cloudschool.ink`
- User Principal Names (UPN) standardized to use the custom domain

### 2. User Provisioning (Bulk Creation)
- 500 student accounts created using PowerShell automation
- 50 staff accounts created using PowerShell automation

### 3. Group Design and Implementation
Student groups are created based on grade and division:

**Grade-level groups**
- GRP-Grade-1
- GRP-Grade-2
- GRP-Grade-3
- GRP-Grade-4
- GRP-Grade-5
- GRP-Grade-6

**Division-level groups**
- GRP-Grade-1a, GRP-Grade-1b, GRP-Grade-1c  
- GRP-Grade-2a, GRP-Grade-2b, GRP-Grade-2c  
- ...  
- GRP-Grade-6a, GRP-Grade-6b, GRP-Grade-6c  

Total student groups: **24**

Staff groups:
- GRP-Staff-All (contains all staff users)
- Department-based groups (example: IT, Admin, Accounts, etc.)

### 4. Attribute Standardization
To maintain identity structure and easy filtering:

| Attribute | Usage |
|----------|--------|
| employeeType | Staff / student |
| extensionAttribute1 | Grade |
| extensionAttribute2 | Division |

employeeType values:
- Staff = `Staff`
- Student = `student`

---

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

Edited

