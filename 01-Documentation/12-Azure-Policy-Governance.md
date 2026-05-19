# Azure Policy Governance

## Purpose

This document explains how Azure Policy is used in the CloudSchool project to control and audit Azure resource deployments.

The current governance implementation focuses on assigning the built-in Azure Policy **Allowed locations** to a development resource group.

## AZ-104 Topic

This work aligns with:

- AZ-104: Manage Azure identities and governance
- Azure Policy
- Policy definitions
- Policy assignments
- Resource group scope
- Compliance validation

## Policy Used

Policy definition:

Allowed locations

Policy type:

Built-in

Policy purpose:

Audits whether Azure resources are deployed only in approved Azure regions.

## Assignment Details

Assignment name:

audit-allowed-locations-rg-compute-dev

Assignment display name:

Audit allowed locations - RG-Compute-Dev

Scope:

/subscriptions/c3413eaf-14ab-4e84-b15f-16b13a063b64/resourceGroups/RG-Compute-Dev

Allowed location:

uaenorth

Effect:

Audit

## Why Audit Was Used

The policy was assigned with the **Audit** effect because this is a safer learning and validation approach.

Audit does not block deployments.

It records compliance state so non-compliant resources can be reviewed.

Deny was not used at this stage because it can block deployments and should only be used after the policy behavior is fully understood.

## Why Resource Group Scope Was Used

The policy was assigned at the resource group scope instead of subscription scope.

Resource group scope is safer for testing because the impact is limited to one resource group.

The selected scope was:

RG-Compute-Dev

This allows governance testing without affecting the full subscription.

## PowerShell Script

Script added:

02-Scripts/12-assign-allowed-location-policy.ps1

The script performs these actions:

- Checks the current Azure PowerShell context
- Confirms the expected subscription ID
- Gets the target resource group
- Uses the resource group ResourceId as the policy assignment scope
- Finds the built-in Azure Policy definition named Allowed locations
- Prepares policy parameters
- Checks whether the policy assignment already exists
- Creates the assignment only if it is missing
- Supports -WhatIf through ShouldProcess

## Idempotency

The script is idempotent.

Before creating the policy assignment, it checks whether the assignment already exists.

If the assignment exists, the script stops safely and does not create a duplicate assignment.

## Validation

The script was tested with -WhatIf.

The script confirmed:

- Correct Azure subscription
- Correct Azure account
- Correct resource group scope
- Built-in policy definition was found
- Policy parameters were prepared
- Existing assignment was detected

The assignment was also verified using Get-AzPolicyAssignment.

Verified assignment:

Name:

audit-allowed-locations-rg-compute-dev

Display name:

Audit allowed locations - RG-Compute-Dev

Scope:

/subscriptions/c3413eaf-14ab-4e84-b15f-16b13a063b64/resourceGroups/RG-Compute-Dev

## Risk and Cost Impact

This policy assignment has no direct Azure cost.

The Audit effect does not block deployments.

The assignment only audits compliance for resources within the selected scope.

## Cleanup

If required, the policy assignment can be removed with Remove-AzPolicyAssignment.

Removing the assignment does not delete Azure resources.

It only removes the governance rule from the selected scope.