# 🎓 CloudSchool – Azure AD User & Group Automation (AZ-104)

## 📌 Project Overview

This project simulates a real-world **school environment** where user lifecycle management is automated using **PowerShell and Microsoft Graph**.

As a Cloud Administrator, the goal is to:

* Create users in bulk (Students & Staff)
* Assign attributes based on organizational structure
* Automatically map users to appropriate groups

---

## 🧱 Architecture Design

### 👨‍🎓 Students

| Attribute           | Value                          |
| ------------------- | ------------------------------ |
| DisplayName         | Student Name                   |
| UPN                 | gr{grade}{division}{id}@domain |
| extensionAttribute1 | Grade                          |
| extensionAttribute2 | Division                       |
| employeeType        | Student                        |

---

### 👨‍🏫 Staff

| Attribute    | Value              |
| ------------ | ------------------ |
| DisplayName  | Staff Name         |
| UPN          | staffname@domain   |
| Department   | IT / HR / Teachers |
| employeeType | Staff              |

---

## 👥 Group Design

### Student Groups

* GRP-Grade1-A
* GRP-Grade1-B

### Staff Groups

* GRP-IT
* GRP-Teachers
* GRP-Staff-All

---

## ⚙️ Automation Workflow

1. Connect to Microsoft Graph
2. Create Student Users (Bulk via CSV)
3. Create Staff Users (Bulk via CSV)
4. Assign Users to Groups dynamically based on attributes

---

## 📂 Scripts Overview

### 🔹 01-connect-mggraph.ps1

Connects to Microsoft Graph with required permissions.

### 🔹 02-create-students.ps1

Creates student accounts and assigns:

* Grade
* Division
* employeeType

### 🔹 03-create-staff.ps1

Creates staff accounts with department mapping.

### 🔹 04-assign-groups.ps1

Assigns users to groups dynamically:

* Students → Grade/Division Groups
* Staff → Department Groups

---

## 🚀 Key Features

* Bulk user creation using CSV
* Attribute-driven identity management
* Scalable group assignment logic
* Real-world naming conventions

---

## 🧠 Future Improvements

* Implement Dynamic Groups
* Add Role-Based Access Control (RBAC)
* Integrate with Azure Automation

---

## 📎 Author

Cloud Administrator Project for AZ-104 Certification

