````markdown
# Attribute Standardization

## Objective

This document defines how user attributes are structured in Entra ID to ensure consistency, automation compatibility, and alignment with group assignment logic.

Attribute standardization is critical for:

- Automated user provisioning
- Dynamic group assignment
- Future policy enforcement (MFA, Conditional Access, RBAC)
- Clean and predictable scripting

---

## Core Attributes Used

The CloudSchool environment uses the following key attributes:

```text
EmployeeType
Department
ExtensionAttribute1
ExtensionAttribute2
````

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

Attributes are directly used to calculate group membership:

```text
Grade01 → GRP-Student-Grade-01
DivisionA → GRP-Student-Grade-01-A
```

No mapping logic is required because attributes align with naming standards.

---

## Staff Attribute Design

### Department

Represents the staff department.

Standardized values include:

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

### Important Standardization Rule

Department values must match group naming.

Rule:

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

## Why Standardization Matters

### 1. Eliminates Mapping Logic

No need for custom translation tables in scripts.

### 2. Enables Direct Automation

Scripts can directly use attribute values to build group names.

### 3. Prevents Errors

Avoids issues like:

```text
GRP-Staff-Student Support (invalid)
GRP-Staff-StudentSupport (inconsistent)
```

### 4. Improves Maintainability

New departments or grades can be added without modifying script logic.

---

## Validation Rules

Before provisioning or updating users, ensure:

* EmployeeType is either `Student` or `Staff`
* Grade format is `Grade0X`
* Division format is `DivisionX`
* Department values contain no spaces (use `_` instead)

---

## Summary

Attribute standardization ensures that:

* Identity data aligns with group naming
* Automation scripts remain simple and reliable
* The environment is scalable and production-ready

This is a key foundation for all future CloudSchool automation and governance.

````

---

Next step:

Send me:

```text
02-Scripts/README.md (raw URL)
````

We’ll update script documentation next.
