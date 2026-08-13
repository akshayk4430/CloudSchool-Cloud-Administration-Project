$shares = Import-Csv -Path ".\03-CSV-Templates\file-shares.csv"

$existingShares = @('staff-shared', 'school-templates')
$results = @()
foreach ($share in $shares) {
    if ($existingShares -contains $share.ShareName) {
        Write-Host "$($share.ShareName) is already available"
        $status = "Exists"
    }
    else {
        Write-Host "$($share.ShareName) is not available"
        $status = "WillCreate"       
    }
    $results += [PSCustomObject]@{
        ShareName  = $share.ShareName
        AccessTier = $share.AccessTier
        Status     = $status
        Timestamp  = Get-Date
    }
}

$results | Format-Table
$results | Export-Csv -Path ".05-Outputs\t12-file-shares-dryrun.csv"