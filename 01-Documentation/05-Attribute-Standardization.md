# Attribute Standardization

## Objective

This document defines how user attributes are structured in Entra ID to ensure consistency, automation compatibility, and alignment with group assignment logic.

Attribute standardization is critical for:

* Automated user provisioning
* Group assignment automation
* Role-based access control
* Policy targeting (MFA, Conditional Access)
* Clean and predictable scripting

---

## Core Attributes Used

The CloudSchool environment uses the following key attributes:

```text
EmployeeType
Department
ExtensionAttribute1
ExtensionAttribute2
```

---

## EmployeeType

Used to distinguish between Students and Staff.

```text
Student
Staff
```

This is the primary decision point in automation logic.

---

## Student Attribute Design

### ExtensionAttribute1 (Grade)

Stores the student grade in a standardized format:

```text
Grade01
Grade02
Grade03
Grade04
Grade05
Grade06
```

---

### ExtensionAttribute2 (Division)

Stores the division:

```text
DivisionA
DivisionB
DivisionC
```

---

### Example Student

```text
UserPrincipalName: std01a001@cloudschool.ink
EmployeeType: Student
ExtensionAttribute1: Grade01
ExtensionAttribute2: DivisionA
```

---

### Group Mapping (Students)

```text
Grade01 → GRP-Student-Grade-01
DivisionA → GRP-Student-Grade-01-A
```

Additional assignments:

```text
All Students → GRP-M365-License-Students
All Students → GRP-Policy-CA-Students
```

---

## Staff Attribute Design

### Department

Represents the staff department.

Standardized values:

```text
IT
Operations
Accounts
Administration
HR
Medical
Library
Transport
Sports
Lab
Management
Academics
Student_Support
Activities
```

---

### ExtensionAttribute1 (Role)

Used to represent staff roles:

```text
ClassTeacher
GradeCoordinator
DeptHead
Principal
Staff
```

---

### Important Standardization Rule

Department values must match group naming.

```text
Spaces are replaced with underscores
```

Example:

```text
Student Support → Student_Support
```

---

### Example Staff

```text
UserPrincipalName: abdul.rasheed@cloudschool.ink
EmployeeType: Staff
Department: Operations
ExtensionAttribute1: DeptHead
```

---

### Group Mapping (Staff)

```text
All staff → GRP-Staff-All
Department → GRP-Staff-<Department>
```

Example:

```text
Operations → GRP-Staff-Operations
Student_Support → GRP-Staff-Student_Support
```

---

### Role-Based Mapping

```text
ClassTeacher      → GRP-Role-ClassTeachers
GradeCoordinator  → GRP-Role-GradeCoordinators
DeptHead          → GRP-Role-DeptHeads
Principal         → GRP-Role-Principal
```

---

### Department-Based Role Mapping

```text
Department = Academics → GRP-Role-Teachers
Department = IT        → GRP-Role-ITAdmins
```

---

### Service / Policy Group Mapping

```text
All Staff → GRP-M365-License-Staff
All Staff → GRP-Policy-CA-Staff
```

---

## Why Standardization Matters

### 1. Eliminates Mapping Complexity

Scripts can directly use attribute values without transformation logic.

---

### 2. Enables Automation

Group names are dynamically constructed from attributes.

---

### 3. Prevents Errors

Avoids inconsistencies such as:

```text
GRP-Staff-Student Support
GRP-Staff-StudentSupport
```

---

### 4. Improves Maintainability

New roles, departments, or grades can be added without changing script logic.

---

## Validation Rules

Before provisioning or updating users:

* EmployeeType must be `Student` or `Staff`
* Grade format must be `Grade0X`
* Division format must be `DivisionX`
* Department must not contain spaces
* Role values must match defined standard

---

## Summary

Attribute standardization ensures:

* Identity data aligns with group structure
* Automation scripts remain simple and reliable
* Role-based and policy-based access is supported
* The environment is scalable and production-ready

This is a core foundation for CloudSchool identity and access management.
