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
$shares = Import-Csv -Path ".\03-CSV-Templates\file-shares.csv"
$results = @()
foreach ($share in $shares) {
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
        $shareObject = New-AzRmStorageShare `
            -ResourceGroupName $share.ResourceGroupName `
            -StorageAccountName $share.StorageAccountName `
            -Name $share.ShareName `
            -QuotaGiB ([int]$share.QuotaGiB) `
            -AccessTier $share.AccessTier
        $status = "Created"       
    }
    $results += [PSCustomObject]@{
        ShareName  = $share.ShareName
        AccessTier = $shareObject.AccessTier
        Status     = $status
        QuotaGiB   = $shareObject.QuotaGiB
        Timestamp  = Get-Date
    }
}

$results | Format-Table
$results | Export-Csv -Path ".\05-Outputs\t12-file-shares.csv"