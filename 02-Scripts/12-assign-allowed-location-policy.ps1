<#
.SYNOPSIS
Assigns the built-in Azure Policy "Allowed locations" to a target resource group.

.DESCRIPTION
Assigns the built-in Azure Policy "Allowed locations" to a target resource group.

The script validates Azure context, confirms the expected subscription, gets the target resource group scope, finds the built-in policy definition,
prepares policy parameters, checks for an existing assignment, and creates the assignment only if it does not already exist.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [string]$ResourceGroupName = "RG-Compute-Dev",

    [string[]]$AllowedLocations = @("uaenorth"),

    [ValidateSet("Audit", "Deny", "Disabled")]
    [string]$Effect = "Audit",

    [string]$AssignmentName = "audit-allowed-locations-rg-compute-dev",

    [string]$AssignmentDisplayName = "Audit allowed locations - RG-Compute-Dev",

    [string]$ExpectedSubscriptionId = "c3413eaf-14ab-4e84-b15f-16b13a063b64"
)

$ErrorActionPreference = "Stop"

Write-Host "CloudSchool Azure Policy Assignment Script" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

# Get current Azure context
Write-Host "Checking Azure context..." -ForegroundColor Yellow

$context = Get-AzContext

if ($null -eq $context) {
    throw "No Azure context found. Run Connect-AzAccount first."
}

$currentSubscriptionId = $context.Subscription.Id

if ($currentSubscriptionId -ne $ExpectedSubscriptionId) {
    throw "Wrong Azure subscription context. Expected $ExpectedSubscriptionId but connected to $currentSubscriptionId."
}

Write-Host "Azure context detected:"
Write-Host "Subscription : $($context.Subscription.Name)"
Write-Host "Account      : $($context.Account.Id)"
Write-Host ""

# Get target resource group
Write-Host "Checking target resource group..." -ForegroundColor Yellow

$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName
$scope = $resourceGroup.ResourceId

Write-Host "Resource group found:"
Write-Host "Name  : $($resourceGroup.ResourceGroupName)"
Write-Host "Scope : $scope"
Write-Host ""

# Get built-in policy definition
Write-Host "Finding built-in policy definition..." -ForegroundColor Yellow

$policyDefinition = Get-AzPolicyDefinition | Where-Object {
    $_.DisplayName -eq "Allowed locations"
}

if ($null -eq $policyDefinition) {
    throw "Built-in policy definition 'Allowed locations' was not found."
}

Write-Host "Policy definition found:"
Write-Host "Display name : $($policyDefinition.DisplayName)"
Write-Host "Definition   : $($policyDefinition.Name)"
Write-Host ""

# Prepare policy parameters
Write-Host "Preparing policy parameters..." -ForegroundColor Yellow

$policyParameters = @{
    listOfAllowedLocations = @{
        value = $AllowedLocations
    }
    effect = @{
        value = $Effect
    }
}

Write-Host "Allowed locations : $($AllowedLocations -join ', ')"
Write-Host "Effect            : $Effect"
Write-Host ""

# Check whether policy assignment already exists
Write-Host "Checking existing policy assignment..." -ForegroundColor Yellow

$existingAssignment = Get-AzPolicyAssignment `
    -Name $AssignmentName `
    -Scope $scope `
    -ErrorAction SilentlyContinue

if ($null -ne $existingAssignment) {
    Write-Host "Policy assignment already exists. No new assignment created." -ForegroundColor Green
    Write-Host "Assignment name : $($existingAssignment.Name)"
    Write-Host "Scope           : $($existingAssignment.Scope)"
    return
}

# Create policy assignment only if missing
Write-Host "Policy assignment does not exist." -ForegroundColor Yellow

$targetDescription = "Policy assignment '$AssignmentName' at scope '$scope'"

if ($PSCmdlet.ShouldProcess($targetDescription, "Create Azure Policy assignment")) {
    $newAssignment = New-AzPolicyAssignment `
        -Name $AssignmentName `
        -DisplayName $AssignmentDisplayName `
        -Scope $scope `
        -PolicyDefinition $policyDefinition `
        -PolicyParameterObject $policyParameters

    Write-Host "Policy assignment created successfully." -ForegroundColor Green
    Write-Host "Assignment name : $($newAssignment.Name)"
    Write-Host "Display name    : $($newAssignment.DisplayName)"
    Write-Host "Scope           : $($newAssignment.Scope)"
}