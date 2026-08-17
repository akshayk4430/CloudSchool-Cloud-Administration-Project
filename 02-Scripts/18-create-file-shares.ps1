
# =============================================================================
# 18-create-file-shares.ps1
# Task 12 - Azure File Shares
#
# Creates SMB file shares on an existing storage account, driven entirely by
# file-shares.csv. Idempotent: existing shares are reported, never recreated.
#
# Prerequisites:
#   - Connected to Azure (Connect-AzAccount) on the CloudSchool tenant
#   - Storage account already exists (created by 16-create-storage-account.ps1)
#   - Az.Storage module available
#
# Output: .\05-Outputs\t12-file-shares.csv
# =============================================================================

# Fail fast if the session is pointing at the wrong tenant or subscription.
$context = Get-AzContext
$expectedTenantId = "401bd5c7-e8b2-4bee-83f6-abf0bad3b953"
$expectedSubscriptionId = "c3413eaf-14ab-4e84-b15f-16b13a063b64"
if (-not $context) {
    throw "Connect to Account first using Connect-AzAccount -tenantID $expectedTenantId"
}

if ($context.Tenant.Id -ne $expectedTenantId) {
    throw "Connect to the correct tenant. Expected Tenant ID : $expectedTenantId"
}
if ($context.Subscription.Id -ne $expectedSubscriptionId) {
    throw "Choose to the correct Subscription. Expected Subscription ID : $expectedSubscriptionId"
}

# CSV is the single source of truth - no share details are hardcoded here.
$shares = Import-Csv -Path ".\03-CSV-Templates\file-shares.csv"
$results = @()
foreach ($share in $shares) {
    # Reset per iteration so a failed create cannot leave the previous share's
    # values in $shareObject and report them against the wrong row.
    $shareObject = $null
    # Query one specific share rather than listing all shares up front, because
    # share names are only unique within a storage account.
    $existingShare = Get-AzRmStorageShare `
        -Name $share.ShareName `
        -ResourceGroupName $share.ResourceGroupName `
        -StorageAccountName $share.StorageAccountName `
        -ErrorAction SilentlyContinue

    if ($existingShare) {
        Write-Host "$($share.ShareName) is already available"
        $shareObject = $existingShare
        $status = "Exists"
    }
    else {
        Write-Host "$($share.ShareName) is not available"
        # -ErrorAction Stop makes the error terminating so catch can handle it.
        # The catch records the failure and lets the loop continue to the next share.
        try {
            $shareObject = New-AzRmStorageShare `
                -ResourceGroupName $share.ResourceGroupName `
                -StorageAccountName $share.StorageAccountName `
                -Name $share.ShareName `
                -QuotaGiB ([int]$share.QuotaGiB) `
                -AccessTier $share.AccessTier `
                -ErrorAction Stop
            $status = "Created"
        }
        catch {
            Write-Warning "Failed to create $($share.ShareName) : $($_.Exception.Message)"
            $status = "Failed"
        }
                   
    }
    # AccessTier and QuotaGiB come from the returned object, not the CSV, so the
    # log reflects what Azure actually provisioned rather than what was requested.
    $results += [PSCustomObject]@{
        ShareName  = $share.ShareName
        AccessTier = $shareObject.AccessTier
        Status     = $status
        QuotaGiB   = $shareObject.QuotaGiB
        Timestamp  = Get-Date
    }
}
# Format-Table is console display only. Export-Csv writes the run log.
$results | Format-Table
$results | Export-Csv -Path ".\05-Outputs\t12-file-shares.csv"