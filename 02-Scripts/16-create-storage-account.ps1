<#
.SYNOPSIS
    CloudSchool - Task 10: Create and configure Azure Storage Account(s)

.DESCRIPTION
    Reads storage-accounts.csv and creates/configures storage accounts for CloudSchool.
    Uses a two-step create-then-set pattern because AllowBlobPublicAccess is only
    settable via Set-AzStorageAccount, not at creation time (Az.Storage v9.6.1).
    Idempotent - safe to re-run. Skips creation if the account already exists,
    but still re-applies the Set-AzStorageAccount config step to correct drift.

.NOTES
    Module   : Az.Storage (v9.6.1 confirmed), Az.Accounts
    Input    : 03-CSV-Templates/storage-accounts.csv
    Output   : 05-Outputs/storage-accounts-result-<timestamp>.csv
    Connect  : Connect-AzAccount -TenantId "401bd5c7-e8b2-4bee-83f6-abf0bad3b953"
#>

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------
$csvPath    = "..\03-CSV-Templates\storage-accounts.csv"
$outputDir  = "..\05-Outputs"
$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$outputPath = Join-Path $outputDir "storage-accounts-result-$timestamp.csv"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# ------------------------------------------------------------
# Import CSV
# ------------------------------------------------------------
if (-not (Test-Path $csvPath)) {
    Write-Error "CSV not found at $csvPath"
    exit 1
}

$storageAccounts = Import-Csv -Path $csvPath
$results = @()

# ------------------------------------------------------------
# Loop rows
# ------------------------------------------------------------
foreach ($row in $storageAccounts) {

    $saName = $row.StorageAccountName
    $rgName = $row.ResourceGroupName

    Write-Host "`nProcessing storage account: $saName (RG: $rgName)" -ForegroundColor Cyan

    # Boolean conversion - CSV values come in as strings ("TRUE"/"FALSE")
    $enableHttps       = [System.Convert]::ToBoolean($row.EnableHttpsTrafficOnly)
    $allowBlobPublic    = [System.Convert]::ToBoolean($row.AllowBlobPublicAccess)
    $enableHns          = [System.Convert]::ToBoolean($row.EnableHierarchicalNamespace)

    $tags = @{
        Environment = $row.Environment
        Project     = $row.Project
    }

    $status = ""
    $errorMessage = ""

    try {
        # --------------------------------------------------------
        # Resolve dependency: Resource Group must exist first
        # --------------------------------------------------------
        $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
        if (-not $rg) {
            throw "Resource group '$rgName' does not exist. Run script 07 first."
        }

        # --------------------------------------------------------
        # Idempotency check - Get- before New-
        # --------------------------------------------------------
        $existing = Get-AzStorageAccount -ResourceGroupName $rgName -Name $saName -ErrorAction SilentlyContinue

        if ($existing) {
            Write-Host "  Storage account already exists - will verify/correct config." -ForegroundColor Yellow
            $status = "AlreadyExists-ConfigChecked"
        }
        else {
            Write-Host "  Creating storage account..." -ForegroundColor Green

            # --------------------------------------------------------
            # Step 1: Create (base properties only)
            # --------------------------------------------------------
            New-AzStorageAccount `
                -ResourceGroupName $rgName `
                -Name $saName `
                -Location $row.Location `
                -SkuName $row.SkuName `
                -Kind $row.Kind `
                -AccessTier $row.AccessTier `
                -EnableHttpsTrafficOnly $enableHttps `
                -MinimumTlsVersion $row.MinimumTlsVersion `
                -EnableHierarchicalNamespace $enableHns `
                -Tag $tags `
                -ErrorAction Stop | Out-Null

            $status = "Created"
        }

        # --------------------------------------------------------
        # Step 2: Set (AllowBlobPublicAccess only settable here)
        # --------------------------------------------------------
        Set-AzStorageAccount `
            -ResourceGroupName $rgName `
            -Name $saName `
            -AllowBlobPublicAccess $allowBlobPublic `
            -MinimumTlsVersion $row.MinimumTlsVersion `
            -Tag $tags `
            -ErrorAction Stop | Out-Null

        Write-Host "  Config applied: AllowBlobPublicAccess=$allowBlobPublic, MinTLS=$($row.MinimumTlsVersion), Tags=$($tags.Keys -join ',')" -ForegroundColor Green
    }
    catch {
        $status = "Failed"
        $errorMessage = $_.Exception.Message
        Write-Host "  ERROR: $errorMessage" -ForegroundColor Red
    }

    # --------------------------------------------------------
    # Build result object
    # --------------------------------------------------------
    $results += [PSCustomObject]@{
        StorageAccountName   = $saName
        ResourceGroupName    = $rgName
        Location             = $row.Location
        SkuName              = $row.SkuName
        Kind                 = $row.Kind
        AccessTier           = $row.AccessTier
        AllowBlobPublicAccess = $allowBlobPublic
        MinimumTlsVersion    = $row.MinimumTlsVersion
        HierarchicalNamespace = $enableHns
        Environment          = $row.Environment
        Project              = $row.Project
        Status               = $status
        ErrorMessage         = $errorMessage
        Timestamp            = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# ------------------------------------------------------------
# Export results
# ------------------------------------------------------------
$results | Export-Csv -Path $outputPath -NoTypeInformation
Write-Host "`nResults exported to: $outputPath" -ForegroundColor Cyan
$results | Format-Table -AutoSize
