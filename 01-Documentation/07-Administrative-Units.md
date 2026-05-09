# 07 - Administrative Units

## Overview

Administrative Units (AUs) are management boundaries inside Microsoft Entra ID.

They are used to limit where delegated administrators can manage users, groups, or devices.

In CloudSchool:

- Groups are used for targeting access, licenses, and policies.
- Administrative Units are used for delegated administration boundaries.

Simple rule:

- Groups control what users receive.
- Administrative Units control who can manage which users.

---

## Current Status

Administrative Units were previously documented as completed, but the current CloudSchool Labs tenant was verified and found to have 0 Administrative Units.

Status:

- Current tenant AU count: 0
- Required AU design: 10 AUs
- Rebuild required: Yes

---

## Design Decision

The project now uses a simplified 10-AU design.

The AU definitions are stored in:

```text
03-CSV-Templates/administrative-units.csv