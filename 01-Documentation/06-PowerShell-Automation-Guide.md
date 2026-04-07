# PowerShell Automation Guide

## 📌 Objective
This document explains how PowerShell is used in this project to automate user and group management tasks in Microsoft Entra ID.

---

## 🛠 Why PowerShell?

Managing hundreds of users manually is not practical.  
PowerShell allows:

- Bulk user creation
- Automated group assignment
- Attribute updates
- Data export and reporting

---

## 🔐 Authentication Method

The project uses Microsoft Graph PowerShell module to connect to Entra ID.

Example:

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"
