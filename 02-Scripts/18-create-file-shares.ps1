$shares = Import-Csv -Path ".\03-CSV-Templates\file-shares.csv"
$rg = "RG-Storage-Prod"
$sa = "stcloudschoolprod001"
$existingSharesObjects = Get-AzRmStorageShare -ResourceGroupName $rg -StorageAccountName $sa -ErrorAction SilentlyContinue
$existingShares = $existingSharesObjects.Name
$results = @()
foreach ($share in $shares) {
    if ($existingShares -contains $share.ShareName) {
        Write-Host "$($share.ShareName) is already available"
        $shareObject = $existingSharesObjects | Where-Object {$_.Name -eq $share.ShareName}
        $status = "Exists"
    }
    else {
        Write-Host "$($share.ShareName) is not available"
        $shareObject = New-AzRmStorageShare `
                        -ResourceGroupName $rg `
                        -StorageAccountName $sa `
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