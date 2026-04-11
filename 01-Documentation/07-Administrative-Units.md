# 07 - Administrative Units

## Overview

Administrative Units (AUs) are boundaries within the Entra ID tenant that restrict 
the scope of admin roles. Without AUs, any delegated admin can manage every user 
in the tenant. AUs fix this by limiting who a delegated admin can manage.

In CloudSchool, AUs ensure that:
- A Grade Coordinator can only manage students in their grade
- A Department Head can only manage staff in their department
- IT Helpdesk cannot accidentally modify staff accounts while managing students

---

## Design Decisions

### Why 17 AUs?

| Category | Count | Details |
|---|---|---|
| Grade AUs | 6 | One per grade (Grade 1 to Grade 6) |
| Department AUs | 10 | Staff grouped by department |
| All-Students AU | 1 | All 500 students in one boundary |
| **Total** | **17** | |

### Department Consolidation

Some departments were small enough to consolidate into shared AUs. 
Each AU description explicitly lists which departments are inside it.

| AU | Departments Included | Reason |
|---|---|---|
| AU-Dept-Operations | Operations, Transport | Operationally related, small teams |
| AU-Dept-Sports | Sports, Activities | Functionally related |
| AU-Dept-StudentSupport | Student Support, Medical | Both serve student welfare |
| AU-Dept-LibraryAndLab | Library, Lab | Both are resource/facility roles |

---

## AU List with Member Counts

### Student AUs

| AU Name | Members | Notes |
|---|---|---|
| AU-All-Students | 500 | All students across all grades |
| AU-Grade-01 | 80 | Grade 1 students (Div A, B, C) |
| AU-Grade-02 | 80 | Grade 2 students (Div A, B, C) |
| AU-Grade-03 | 80 | Grade 3 students (Div A, B, C) |
| AU-Grade-04 | 80 | Grade 4 students (Div A, B, C) |
| AU-Grade-05 | 90 | Grade 5 students (Div A, B, C) |
| AU-Grade-06 | 90 | Grade 6 students (Div A, B, C) |

> Note: Grade distribution is uneven by design — Grades 5 and 6 have 
> more students. Total across all grade AUs = 500, which is correct.

### Staff AUs

| AU Name | Departments | Members |
|---|---|---|
| AU-Dept-Management | Management | 5 |
| AU-Dept-IT | IT | 5 |
| AU-Dept-Academics | Academics | 6 |
| AU-Dept-Administration | Administration | 4 |
| AU-Dept-Accounts | Accounts | 4 |
| AU-Dept-HR | HR | 2 |
| AU-Dept-Operations | Operations, Transport | 6 |
| AU-Dept-Sports | Sports, Activities | 7 |
| AU-Dept-StudentSupport | Student Support, Medical | 6 |
| AU-Dept-LibraryAndLab | Library, Lab | 5 |

---

## Implementation

### Step 1 — Manual (Portal)

AU-Grade-01 was created manually in the Entra portal as a learning exercise 
before automation. This was intentional — to understand every field and option 
before scripting the rest.

**Portal path:**
Microsoft Entra → Administrative units → + Add

### Step 2 — Automated (PowerShell)

All remaining 16 AUs were created and populated using:
`02-Scripts/05-create-administrative-units.ps1`

The script:
- Checks if the AU already exists before creating (safe to re-run)
- Checks existing members before adding (no duplicates)
- Assigns students by `department` field (Grade1–Grade6)
- Assigns staff by `department` field (IT, HR, etc.)

---

## Required Graph Scope

This is different from earlier scripts. You must connect with:

```powershell
Connect-MgGraph -Scopes "AdministrativeUnit.ReadWrite.All"
```

Using only `Directory.ReadWrite.All` or `User.ReadWrite.All` will result 
in a 403 Forbidden error when trying to create or modify AUs.

---

## What Comes Next

These AUs are the foundation for **Role Delegation (Task 07)**.

In the next phase, scoped admin roles will be assigned to specific staff 
members within these AU boundaries. For example:
- Grade Coordinator → Password Administrator scoped to their grade AU
- Department Head → User Administrator scoped to their department AU

No role assignments are made in this task. AUs only define the boundary.

---

## Script Output (Execution Log)

```
[INFO] Students fetched: 500
[INFO] Staff fetched: 50

AU-All-Students         — Created | Added: 500 | Skipped: 0
AU-Grade-01             — Existed | Added: 77  | Skipped: 3
AU-Grade-02             — Created | Added: 80  | Skipped: 0
AU-Grade-03             — Created | Added: 80  | Skipped: 0
AU-Grade-04             — Created | Added: 80  | Skipped: 0
AU-Grade-05             — Created | Added: 90  | Skipped: 0
AU-Grade-06             — Created | Added: 90  | Skipped: 0
AU-Dept-Management      — Created | Added: 5   | Skipped: 0
AU-Dept-IT              — Created | Added: 5   | Skipped: 0
AU-Dept-Academics       — Created | Added: 6   | Skipped: 0
AU-Dept-Administration  — Created | Added: 4   | Skipped: 0
AU-Dept-Accounts        — Created | Added: 4   | Skipped: 0
AU-Dept-HR              — Created | Added: 2   | Skipped: 0
AU-Dept-Operations      — Created | Added: 6   | Skipped: 0
AU-Dept-Sports          — Created | Added: 7   | Skipped: 0
AU-Dept-StudentSupport  — Created | Added: 6   | Skipped: 0
AU-Dept-LibraryAndLab   — Created | Added: 5   | Skipped: 0

Total AUs processed: 17
Expected total: 17
```
