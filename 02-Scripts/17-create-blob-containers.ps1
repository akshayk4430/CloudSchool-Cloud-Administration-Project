<#
.SYNOPSIS
    CloudSchool - Task 11 - Blob container provisioning.

.DESCRIPTION
    Applies blob service soft delete settings and provisions blob containers
    from CSV. Data plane operations authenticate with the signed-in Entra
    identity, which requires Storage Blob Data Contributor on the storage
    account. Control plane role membership such as Owner is NOT sufficient.

    Idempotent. Safe to re-run.

.NOTES
    Author  : Akshay Kattoth
    Project : CloudSchool
    Task    : T11 - Blob Storage
#>

[CmdletBinding()]
param(
    [string]$ContainerCsvPath       = "$PSScriptRoot\..\03-CSV-Templates\blob-containers.csv",
    [string]$ServicePropertyCsvPath = "$PSScriptRoot\..\03-CSV-Templates\blob-service-properties.csv",
    [string]$OutputFolder           = "$PSScriptRoot\..\05-Outputs",
    [string]$TenantId               = "401bd5c7-e8b2-4bee-83f6-abf0bad3b953"
)

$ErrorActionPreference = 'Stop'
$results   = @()
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# ---------------------------------------------------------------------------
# 1. Preflight
# ---------------------------------------------------------------------------

foreach ($path in @($ContainerCsvPath, $ServicePropertyCsvPath)) {
    if (-not (Test-Path -Path $path)) {
        throw "CSV not found: $path"
    }
}

if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

$context = Get-AzContext
if (-not $context) {
    throw "Not connected to Azure. Run: Connect-AzAccount -TenantId $TenantId"
}
if ($context.Tenant.Id -ne $TenantId) {
    throw "Connected to tenant $($context.Tenant.Id) but expected $TenantId."
}

Write-Host "Signed in as : $($context.Account.Id)" -ForegroundColor Cyan
Write-Host "Subscription : $($context.Subscription.Name)" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 2. Blob service properties (control plane)
# ---------------------------------------------------------------------------

$serviceRow = Import-Csv -Path $ServicePropertyCsvPath | Select-Object -First 1

$accountName   = $serviceRow.StorageAccountName
$resourceGroup = $serviceRow.ResourceGroupName

$blobSoftDelete      = [System.Convert]::ToBoolean($serviceRow.BlobSoftDeleteEnabled)
$blobRetentionDays   = [int]$serviceRow.BlobSoftDeleteRetentionDays
$containerSoftDelete = [System.Convert]::ToBoolean($serviceRow.ContainerSoftDeleteEnabled)
$containerRetention  = [int]$serviceRow.ContainerSoftDeleteRetentionDays

Write-Host "`nApplying blob service properties on $accountName ..." -ForegroundColor Yellow

try {
    if ($blobSoftDelete) {
        Enable-AzStorageBlobDeleteRetentionPolicy `
            -ResourceGroupName $resourceGroup `
            -StorageAccountName $accountName `
            -RetentionDays $blobRetentionDays
        Write-Host "  Blob soft delete      : enabled ($blobRetentionDays days)" -ForegroundColor Green
    }
    else {
        Disable-AzStorageBlobDeleteRetentionPolicy `
            -ResourceGroupName $resourceGroup `
            -StorageAccountName $accountName `
            -Confirm:$false
        Write-Host "  Blob soft delete      : disabled" -ForegroundColor DarkGray
    }

    if ($containerSoftDelete) {
        Enable-AzStorageContainerDeleteRetentionPolicy `
            -ResourceGroupName $resourceGroup `
            -StorageAccountName $accountName `
            -RetentionDays $containerRetention
        Write-Host "  Container soft delete : enabled ($containerRetention days)" -ForegroundColor Green
    }
    else {
        Disable-AzStorageContainerDeleteRetentionPolicy `
            -ResourceGroupName $resourceGroup `
            -StorageAccountName $accountName `
            -Confirm:$false
        Write-Host "  Container soft delete : disabled" -ForegroundColor DarkGray
    }
}
catch {
    Write-Warning "Failed to apply blob service properties: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 3. Storage context (data plane, Entra identity)
# ---------------------------------------------------------------------------

$ctx = New-AzStorageContext -StorageAccountName $accountName -UseConnectedAccount

# ---------------------------------------------------------------------------
# 4. Provision containers
# ---------------------------------------------------------------------------

$containers = Import-Csv -Path $ContainerCsvPath
Write-Host "`nProcessing $($containers.Count) containers ...`n" -ForegroundColor Yellow

foreach ($row in $containers) {

    $name       = $row.ContainerName.Trim()
    $permission = $row.PublicAccess.Trim()
    $action     = 'Unknown'
    $message    = ''
    $actual     = ''

    try {
        if ($name -cne $name.ToLower()) {
            throw "Container name must be lowercase."
        }

        $existing = $null
        try {
            $existing = Get-AzStorageContainer -Name $name -Context $ctx -ErrorAction Stop
        }
        catch {
            $existing = $null
        }

        if ($null -eq $existing) {
            $created = New-AzStorageContainer -Name $name -Permission $permission -Context $ctx
            $action  = 'Created'
            $actual  = if ($created.PublicAccess) { $created.PublicAccess } else { 'Off' }
            Write-Host "  [Created]       $name" -ForegroundColor Green
        }
        else {
            $current = if ($existing.PublicAccess) { $existing.PublicAccess.ToString() } else { 'Off' }

            if ($current -ne $permission) {
                Set-AzStorageContainerAcl -Name $name -Permission $permission -Context $ctx | Out-Null
                $action  = 'Updated'
                $message = "Public access corrected from $current to $permission"
                $actual  = $permission
                Write-Host "  [Updated]       $name - $message" -ForegroundColor Yellow
            }
            else {
                $action = 'AlreadyExists'
                $actual = $current
                Write-Host "  [AlreadyExists] $name" -ForegroundColor DarkGray
            }
        }
    }
    catch {
        $action  = 'Failed'
        $message = $_.Exception.Message
        Write-Host "  [Failed]        $name - $message" -ForegroundColor Red
    }

    $results += [PSCustomObject]@{
        ContainerName         = $name
        Purpose               = $row.Purpose
        PublicAccessRequested = $permission
        PublicAccessActual    = $actual
        Action                = $action
        Message               = $message
        StorageAccount        = $accountName
        ResourceGroup         = $resourceGroup
        RunTimestamp          = $timestamp
    }
}

# ---------------------------------------------------------------------------
# 5. Export
# ---------------------------------------------------------------------------

$outputPath = Join-Path -Path $OutputFolder -ChildPath "blob-containers-result-$timestamp.csv"
$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Host "`nSummary" -ForegroundColor Cyan
$results | Group-Object Action | ForEach-Object {
    Write-Host ("  {0,-14} {1}" -f $_.Name, $_.Count)
}
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Cyan
