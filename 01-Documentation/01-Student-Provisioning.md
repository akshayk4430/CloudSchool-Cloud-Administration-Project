# Student Provisioning Automation

## Overview

This script validates and updates student user accounts in Microsoft Entra ID using a structured CSV as the source of truth.

The script ensures that:

* existing users are aligned with defined attributes
* incorrect attributes are corrected
* already correct users are skipped
* the script can be safely re-run (idempotent behavior)

---

## Objective

To implement a production-style identity management process for student accounts, including:

* standardized user attributes
* automated validation against source data
* controlled updates using Microsoft Graph PowerShell
* logging and reporting of all actions

---

## Data Source

File:

```
03-CSV-Templates/students.csv
```

Structure:

```
UserPrincipalName
DisplayName
GivenName
Surname
MailNickname
Department
EmployeeType
UsageLocation
ExtensionAttribute1
ExtensionAttribute2
```

Key design decisions:

* `UserPrincipalName` follows structured format (e.g., `std01a001@cloudschool.ink`)
* `DisplayName`, `GivenName`, `Surname` use real names
* `ExtensionAttribute1` → Grade (e.g., `Grade01`)
* `ExtensionAttribute2` → Division (e.g., `DivisionA`)
* CSV acts as the single source of truth

---

## Script Location

```
02-Scripts/02-create-students.ps1
```

---

## Script Logic

### 1. Import CSV

Reads student records into objects for processing.

### 2. User Lookup

Each user is queried using Microsoft Graph:

```
Get-MgUser -Filter "userPrincipalName eq '<UPN>'"
```

### 3. Decision Logic

| Condition                  | Action                         |
| -------------------------- | ------------------------------ |
| User not found             | Create *(not implemented yet)* |
| User exists but mismatched | Update                         |
| User exists and matches    | Skip                           |

### 4. Attribute Comparison

The script compares:

* DisplayName
* GivenName
* Surname
* Department
* EmployeeType
* UsageLocation
* ExtensionAttribute1
* ExtensionAttribute2

### 5. Update Execution

Only mismatched fields are updated using:

```
Update-MgUser
```

Update parameters are built dynamically to avoid unnecessary API calls.

### 6. Logging

Results are exported to:

```
05-Outputs/students-results.csv
```

Each row includes:

* UserPrincipalName
* Action (Create / Update / Skip)
* Status (Success / Failed)
* Notes (details or error message)

---

## Idempotency

The script is designed to be re-runnable without side effects.

Final validation:

| Run        | Result              |
| ---------- | ------------------- |
| First run  | 497 Update / 3 Skip |
| Second run | 500 Skip            |

This confirms:

* all users are aligned with CSV
* no redundant updates occur

---

## Error Handling

Update operations are wrapped in `try/catch`:

* Success → logged as `Success`
* Failure → logged as `Failed` with error message

This ensures traceability for large-scale operations.

---

## Testing Approach

Testing was performed in stages:

1. 3-user validation (controlled test)
2. mismatch simulation (forced update scenario)
3. full dataset execution (500 users)
4. idempotency verification (second run)

---

## Key Learnings

* CSV must be clean and consistent before automation
* Graph queries require correct property selection
* attribute mismatches must be explicitly compared
* idempotent scripts are critical for production environments
* structured logging is required for audit and troubleshooting

---

## Current Status

* Student data fully aligned with Entra ID
* Script validated and production-ready for update operations
* Safe for repeated execution

---

## Next Phase

* Implement user creation logic for new students
* Apply the same model to staff provisioning
* Enhance logging and reporting if required

---


