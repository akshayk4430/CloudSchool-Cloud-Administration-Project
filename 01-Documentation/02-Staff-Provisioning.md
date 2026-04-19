# Staff Provisioning

## Overview

This phase covers the cleanup, modeling, and automation of staff identity provisioning for the CloudSchool tenant.

The goal was to replace fragmented one-time scripts with a reusable PowerShell workflow that supports:

- Create
- Update
- Skip
- Idempotent re-run

This staff provisioning process was built to align with the same structured approach used for student provisioning, while also handling role-based staff attributes.

---

## Objectives

The staff provisioning workflow was designed to:

- standardize staff identity data
- separate identity data from business attribute mapping
- support safe re-runs without duplicate creation
- update only changed fields
- populate extension attributes for staff role and assignment
- generate result output for validation

---

## Source Files

### Scripts

- `02-Scripts/08-build-staff-csv.ps1`
- `02-Scripts/09-merge-staff-csv.ps1`
- `02-Scripts/03-create-staff.ps1`

### CSV Files

- `03-CSV-Templates/staff-only-export.csv`
- `03-CSV-Templates/staff.csv`
- `03-CSV-Templates/staff-attributes.csv`
- `03-CSV-Templates/staff-final.csv`

### Output

- `05-Outputs/staff-provisioning-results.csv`

---

## Workflow

### 1. Export cleanup

Raw exported staff data was cleaned and normalized using:

`08-build-staff-csv.ps1`

This step:

- fixed missing `GivenName` and `Surname`
- standardized `MailNickname`
- standardized `UsageLocation`
- standardized `EmployeeType`

Output:

`staff.csv`

---

### 2. Attribute mapping

Staff role and assignment data was maintained separately in:

`staff-attributes.csv`

This file contains:

- `ExtensionAttribute1` = Role
- `ExtensionAttribute2` = Assignment

Examples:

- Principal
- VicePrincipal
- DeptHead
- GradeCoordinator
- ClassTeacher
- Staff

Examples of assignments:

- Management
- IT
- Accounts
- Operations
- Grade1A
- Grade2B

---

### 3. Merge step

The identity dataset and attribute mapping dataset were merged using:

`09-merge-staff-csv.ps1`

Output:

`staff-final.csv`

This final CSV is the source of truth for provisioning.

---

### 4. Provisioning logic

Provisioning is handled by:

`03-create-staff.ps1`

The script performs:

- user existence check
- create missing users
- compare existing users
- update only changed fields
- update `ExtensionAttribute1`
- update `ExtensionAttribute2`
- skip already-correct users
- export provisioning results

---

## Final CSV Structure

`staff-final.csv` contains:

- `UserPrincipalName`
- `DisplayName`
- `GivenName`
- `Surname`
- `MailNickname`
- `Department`
- `EmployeeType`
- `UsageLocation`
- `ExtensionAttribute1`
- `ExtensionAttribute2`

---

## Provisioning Results

The provisioning script exports results to:

`05-Outputs/staff-provisioning-results.csv`

The result file contains:

- `UserPrincipalName`
- `DisplayName`
- `Action`
- `Status`
- `Notes`

### Action values

- `Create`
- `Update`
- `Skip`

### Status values

- `Success`
- `Failed`

---

## Validation Summary

The final staff workflow was validated with the following outcomes:

- existing users were detected correctly
- changed users were updated correctly
- missing users could be created successfully
- extension attributes were written successfully
- re-running the script resulted in all users being skipped when already correct

This confirms that the workflow is idempotent.

---

## Notes

This implementation is production-style for portfolio use, but further hardening could include:

- transcript logging
- retry handling
- secure password handling
- stricter error classification
- separate post-provisioning steps for licensing and group assignment