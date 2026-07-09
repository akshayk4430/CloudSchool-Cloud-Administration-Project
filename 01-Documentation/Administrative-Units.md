# 07 - Administrative Units

## What is an Administrative Unit

An Administrative Unit (AU) is a boundary inside Microsoft Entra ID used to scope delegated admin permissions. Unlike groups, which control what users receive (licenses, policies, app access), AUs control who can manage which users.

For example, in CloudSchool, a Class Teacher of Grade 6B is assigned the Helpdesk Administrator role scoped to `AU-CloudSchool-Grade-06-B`. This means she can reset passwords for students in that AU only — she cannot touch students in any other grade or division, and she has no access to staff accounts.

---

## Design Decision

CloudSchool uses 28 Administrative Units following the principle of least privilege — a core security best practice in Microsoft Entra ID and Azure.

The design is split into two levels:

**Grade-level AUs (8 total):** For Grade Coordinators who need to manage all students within a grade. Example: `AU-CloudSchool-Grade-06` contains all 90 Grade 6 students across all three divisions.

**Division-level AUs (18 total):** For Class Teachers who should only manage their own class. Example: `AU-CloudSchool-Grade-06-B` contains only the 30 students in Grade 6, Division B.

**Category AUs (2 total):** `AU-CloudSchool-All-Students` and `AU-CloudSchool-All-Staff` for tenant-wide admin delegation when needed.

This design ensures no teacher has broader access than their actual job requires.

---

## Implementation

The AU creation and population process is fully automated using a CSV-driven PowerShell script (`06-create-administrative-units.ps1`).

**Source of truth:** `03-CSV-Templates/administrative-units.csv` defines all 28 AUs with the following columns: AUName, Description, UserType, DepartmentFilter, and DivisionFilter.

**Script logic (in order):**

1. Validates the CSV exists and contains all required columns
2. Fetches all 556 users from Entra ID once upfront into memory — avoids repeated API calls which would hurt performance
3. Fetches all existing AUs once upfront for the same reason
4. Loops through each CSV row and checks if the AU already exists — creates it if missing, skips if already present
5. Filters users using three layers: UserType (Student or Staff), DepartmentFilter (grade or department), and DivisionFilter (division — only applied when not `*`)
6. For each matching user — adds them to the AU if not already a member, skips if already present
7. Logs every AU's result (Created/Existed, matched users, added, skipped, failed) to an output CSV

The script is fully idempotent — safe to re-run at any time without duplicating data.

---

## Administrative Units — Full List

| AU Name | Type | Purpose |
|---------|------|---------|
| AU-CloudSchool-All-Students | Category | All 500 students |
| AU-CloudSchool-All-Staff | Category | All 55 staff |
| AU-CloudSchool-Grade-01 | Grade | All 80 Grade 1 students |
| AU-CloudSchool-Grade-02 | Grade | All 80 Grade 2 students |
| AU-CloudSchool-Grade-03 | Grade | All 80 Grade 3 students |
| AU-CloudSchool-Grade-04 | Grade | All 80 Grade 4 students |
| AU-CloudSchool-Grade-05 | Grade | All 90 Grade 5 students |
| AU-CloudSchool-Grade-06 | Grade | All 90 Grade 6 students |
| AU-CloudSchool-IT | Category | IT department staff (6) |
| AU-CloudSchool-Management | Category | Management staff (5) |
| AU-CloudSchool-Grade-01-A/B/C | Division | 27/27/26 Grade 1 students per division |
| AU-CloudSchool-Grade-02-A/B/C | Division | 27/27/26 Grade 2 students per division |
| AU-CloudSchool-Grade-03-A/B/C | Division | 27/27/26 Grade 3 students per division |
| AU-CloudSchool-Grade-04-A/B/C | Division | 27/27/26 Grade 4 students per division |
| AU-CloudSchool-Grade-05-A/B/C | Division | 30/30/30 Grade 5 students per division |
| AU-CloudSchool-Grade-06-A/B/C | Division | 30/30/30 Grade 6 students per division |