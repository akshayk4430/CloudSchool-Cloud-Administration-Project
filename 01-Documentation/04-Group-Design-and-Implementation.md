
---

# Group Design and Implementation

## Objective

The goal of this design is to organize CloudSchool users in a structured, scalable, and automation-friendly way.

Groups are used to manage access, policies, Microsoft 365 workloads, Teams, SharePoint, and future Azure-based assignments.

---

## Group Naming Convention

All groups follow this standard:

```text
GRP-<EmployeeType>-<Logical Unit>
```

Examples:

```text
GRP-Student-Grade-01
GRP-Student-Grade-01-A
GRP-Staff-All
GRP-Staff-IT
GRP-Staff-Operations
```

This keeps group names aligned with the identity model used in Entra ID.

---

## Group Strategy

Users are grouped based on:

* EmployeeType
* Grade
* Division
* Department

The group assignment script uses Entra ID user attributes to calculate the correct group memberships.

---

## Student Group Structure

Student groups are based on grade and division.

### Grade-Level Groups

```text
GRP-Student-Grade-01
GRP-Student-Grade-02
GRP-Student-Grade-03
GRP-Student-Grade-04
GRP-Student-Grade-05
GRP-Student-Grade-06
```

### Division-Level Groups

```text
GRP-Student-Grade-01-A
GRP-Student-Grade-01-B
GRP-Student-Grade-01-C
```

This structure is repeated for Grades 01 to 06.

Total student groups:

```text
6 grade groups + 18 division groups = 24 student groups
```

---

## Staff Group Structure

Staff groups are based on department.

### All Staff Group

```text
GRP-Staff-All
```

### Department Groups

```text
GRP-Staff-IT
GRP-Staff-Operations
GRP-Staff-Accounts
GRP-Staff-Academics
GRP-Staff-Student_Support
```

Department names are standardized (spaces replaced with underscores).

---

## Identity Attribute Alignment

### Students

```text
EmployeeType = Student
ExtensionAttribute1 = Grade
ExtensionAttribute2 = Division
```

Example:

```text
ExtensionAttribute1 = Grade01
ExtensionAttribute2 = DivisionA
```

---

### Staff

```text
EmployeeType = Staff
Department = Department Name
```

Example:

```text
Department = Operations
```

---

## Automation Method

```text
02-Scripts/04-Create-Groups.ps1 → Creates groups
02-Scripts/05-Assign-Users-To-Groups.ps1 → Assigns users
```

Both scripts are idempotent.

Features:

* Add missing groups/memberships
* Skip existing ones
* Log results
* Export to CSV
* Cache groups and memberships
* Prevent duplicate operations

Output:

```text
05-Outputs/group-assignment-results.csv
```

---

## Group Creation Automation

Script:

```text
02-Scripts/04-Create-Groups.ps1
```

Source of truth:

```text
03-CSV-Templates/groups-required.csv
```

Features:

* CSV-driven group definition
* Create / Skip / Failed logic
* Safe to re-run
* Output logging

Total groups:

```text
49 groups
```

---

## Group Categories

### 1. Organizational Groups

* Student groups (Grade + Division)
* Staff groups (Department)

---

### 2. Role-Based Groups

```text
GRP-Role-Teachers
GRP-Role-ClassTeachers
GRP-Role-DeptHeads
GRP-Role-Principal
GRP-Role-ITAdmins
```

---

### 3. Service / Policy Groups

```text
GRP-M365-License-Students
GRP-M365-License-Staff
GRP-Policy-CA-Students
GRP-Policy-CA-Staff
```

---

## Group Assignment Logic

### Students

```text
GRP-Student-Grade-*
GRP-Student-Grade-*-*
GRP-M365-License-Students
GRP-Policy-CA-Students
```

---

### Staff

```text
GRP-Staff-All
GRP-Staff-<Department>
GRP-M365-License-Staff
GRP-Policy-CA-Staff
```

---

### Role-Based Assignment

```text
ExtensionAttribute1 = ClassTeacher      → GRP-Role-ClassTeachers
ExtensionAttribute1 = GradeCoordinator  → GRP-Role-GradeCoordinators
ExtensionAttribute1 = DeptHead          → GRP-Role-DeptHeads
ExtensionAttribute1 = Principal         → GRP-Role-Principal
Department = Academics                  → GRP-Role-Teachers
Department = IT                         → GRP-Role-ITAdmins
```

---

## Idempotent Design

* Create-Groups → Create / Skip / Failed
* Assign-Users → Add / Skip / Failed

Scripts can be safely re-run without duplication.

---

## Design Benefits

* Consistent naming
* Automation-friendly
* Scalable
* Policy-ready
* Safe re-execution

---

## Summary

CloudSchool group design is based on:

* Organizational structure
* Role-based access
* Service and policy targeting

This enables clean automation, scalable identity management, and real-world alignment with Microsoft 365 and Azure practices.

---
