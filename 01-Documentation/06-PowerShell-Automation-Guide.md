# PowerShell Automation Guide

## Objective

This document explains how PowerShell is used to automate identity and group management in the CloudSchool environment using Microsoft Graph.

---

## Why PowerShell?

Managing hundreds of users manually is not practical.

PowerShell enables:

* Bulk user provisioning
* Automated group creation
* Automated group assignment
* Attribute standardization
* Export and reporting
* Idempotent operations

---

## Authentication

The project uses Microsoft Graph PowerShell module:

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"
```

---

## Automation Architecture

The automation is designed as a pipeline:

```text
CSV → Script → Entra ID → Validation Output
```

Key principles:

* CSV is the source of truth
* Scripts compare before updating
* Only required changes are applied
* Scripts are safe to re-run

---

## Script Overview

### 01-connect-mggraph.ps1

* Connects to Microsoft Graph
* Required before running any other script

---

### 02-create-students.ps1

* Reads `students.csv`
* Creates new users
* Updates existing users if changes detected
* Skips users already in correct state
* Applies:

  * EmployeeType
  * ExtensionAttribute1 (Grade)
  * ExtensionAttribute2 (Division)

---

### 03-create-staff.ps1

* Reads `staff-final.csv`
* Handles:

  * Create / Update / Skip logic
  * Department assignment
  * Role assignment (ExtensionAttribute1)

---

### 04-Create-Groups.ps1

* Reads `groups-required.csv`
* Creates missing groups
* Skips existing groups
* Idempotent design

Output:

```text
05-Outputs/group-creation-results.csv
```

---

### 05-Assign-Users-To-Groups.ps1

* Assigns users to groups based on attributes

Student logic:

```text
Grade + Division → Student groups  
License + Policy → Service groups  
```

Staff logic:

```text
All staff + Department → Organizational groups  
License + Policy → Service groups  
Role + Department → Role-based groups  
```

Features:

* Caches groups and memberships
* Checks membership before adding
* Prevents duplicate operations
* Logs results

Output:

```text
05-Outputs/group-assignment-results.csv
```

---

### 06-create-administrative-units.ps1

* Creates administrative units
* Assigns users based on attributes
* Used for delegation and RBAC scenarios

---

## Idempotent Design

All scripts follow:

```text
Create / Update / Skip / Failed
```

This ensures:

* No duplicate users or groups
* No unnecessary API calls
* Safe re-execution

---

## Logging and Validation

All scripts generate output files:

* student results
* staff provisioning results
* group creation results
* group assignment results

These are used for:

* Validation
* Troubleshooting
* Audit tracking

---

## Key Benefits

* Scalable automation for large environments
* Minimal manual intervention
* Consistent identity structure
* Real-world production design
* Optimized Microsoft Graph usage

---

## Summary

PowerShell automation in CloudSchool provides a complete identity lifecycle:

* User provisioning
* Group creation
* Group assignment
* Attribute standardization

This approach reflects real-world enterprise cloud administration practices.
