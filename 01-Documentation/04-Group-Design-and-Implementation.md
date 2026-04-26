````markdown
# Group Design and Implementation

## Objective

The goal of this design is to organize CloudSchool users in a structured, scalable, and automation-friendly way.

Groups are used to manage access, policies, Microsoft 365 workloads, Teams, SharePoint, and future Azure-based assignments.

---

## Group Naming Convention

All groups follow this standard:

```text
GRP-<EmployeeType>-<Logical Unit>
````

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

Each grade has one grade-level group:

```text
GRP-Student-Grade-01
GRP-Student-Grade-02
GRP-Student-Grade-03
GRP-Student-Grade-04
GRP-Student-Grade-05
GRP-Student-Grade-06
```

### Division-Level Groups

Each grade has three division-level groups:

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

This group contains all staff users.

### Department Groups

Examples:

```text
GRP-Staff-IT
GRP-Staff-Operations
GRP-Staff-Accounts
GRP-Staff-Academics
GRP-Staff-Student_Support
```

Department names are standardized to align with group naming. Spaces are replaced with underscores where required.

Example:

```text
Student Support → Student_Support
```

---

## Identity Attribute Alignment

Group assignment is based on the following Entra ID attributes:

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

Assigned groups:

```text
GRP-Student-Grade-01
GRP-Student-Grade-01-A
```

### Staff

```text
EmployeeType = Staff
Department = Department Name
```

Example:

```text
Department = Operations
```

Assigned groups:

```text
GRP-Staff-All
GRP-Staff-Operations
```

---

## Automation Method

Group assignment is handled by:

```text
02-Scripts/04-Assign-Users-To-Groups.ps1
```

The script is designed to be idempotent.

It supports:

* Adding missing memberships
* Skipping existing memberships
* Logging failed assignments
* Exporting results to CSV
* Caching groups before processing users
* Checking membership before adding users

Output file:

```text
05-Outputs/group-assignment-results.csv
```

---

## Design Benefits

### 1. Consistent Naming

All group names follow a predictable standard.

### 2. Automation Friendly

The script can calculate memberships directly from user attributes.

### 3. Scalable

New grades, divisions, or departments can be added without redesigning the full structure.

### 4. Policy Ready

Groups can be used later for Microsoft 365, Teams, SharePoint, Conditional Access, licensing, and Azure resource access.

### 5. Idempotent Operations

The script can be safely re-run without duplicating memberships.

---

## Summary

The CloudSchool group structure is now standardized around EmployeeType and logical units.

Students are grouped by grade and division.

Staff are grouped by department.

This structure supports clean automation, access management, and future Microsoft 365 and Azure policy assignments.

```

After saving this file in GitHub, send me the next raw URL for `05-Attribute-Standardization.md`.
::contentReference[oaicite:0]{index=0}
```
