param (
    [string]$CsvPath = ".\03-CSV-Templates\vnets.csv",
    [string]$OutputPath = ".\05-Outputs\vnet-subnet-results.csv"
)

$results = @()

if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

$outputFolder = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

$vnets = Import-Csv $CsvPath

$requiredColumns = @(
    "Environment",
    "ResourceGroupName",
    "Location",
    "VNetName",
    "AddressSpace",
    "SubnetName",
    "SubnetPrefix"
)

foreach ($column in $requiredColumns) {
    if ($column -notin $vnets[0].PSObject.Properties.Name) {
        throw "Missing required CSV column: $column"
    }
}

$vnetGroups = $vnets | Group-Object VNetName

foreach ($group in $vnetGroups) {

    $vnetData = $group.Group[0]

    $environment = $vnetData.Environment
    $rgName      = $vnetData.ResourceGroupName
    $location    = $vnetData.Location
    $vnetName    = $vnetData.VNetName
    $address     = $vnetData.AddressSpace

    try {
        $existingRG = Get-AzResourceGroup -Name $rgName -ErrorAction Stop
    }
    catch {
        $results += [PSCustomObject]@{
            Environment       = $environment
            ResourceGroupName = $rgName
            VNetName          = $vnetName
            SubnetName        = ""
            Action            = "Failed"
            Reason            = "Resource group not found"
        }

        Write-Warning "Resource group not found: $rgName"
        continue
    }

    try {
        $existingVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

        if (-not $existingVnet) {

            Write-Host "CREATING VNET: $vnetName"

            $subnetConfigs = @()

            foreach ($subnet in $group.Group) {
                $subnetConfigs += New-AzVirtualNetworkSubnetConfig `
                    -Name $subnet.SubnetName `
                    -AddressPrefix $subnet.SubnetPrefix
            }

            New-AzVirtualNetwork `
                -Name $vnetName `
                -ResourceGroupName $rgName `
                -Location $location `
                -AddressPrefix $address `
                -Subnet $subnetConfigs `
                -ErrorAction Stop | Out-Null

            foreach ($subnet in $group.Group) {
                $results += [PSCustomObject]@{
                    Environment       = $environment
                    ResourceGroupName = $rgName
                    VNetName          = $vnetName
                    SubnetName        = $subnet.SubnetName
                    Action            = "Created"
                    Reason            = "VNet and subnet created"
                }
            }
        }
        else {

            Write-Host "VNET EXISTS: $vnetName"

            $vnetChanged = $false

            foreach ($subnet in $group.Group) {

                $existingSubnet = $existingVnet.Subnets | Where-Object {
                    $_.Name -eq $subnet.SubnetName
                }

                if (-not $existingSubnet) {

                    Write-Host "ADDING SUBNET: $($subnet.SubnetName)"

                    Add-AzVirtualNetworkSubnetConfig `
                        -Name $subnet.SubnetName `
                        -AddressPrefix $subnet.SubnetPrefix `
                        -VirtualNetwork $existingVnet `
                        -ErrorAction Stop | Out-Null

                    $vnetChanged = $true

                    $results += [PSCustomObject]@{
                        Environment       = $environment
                        ResourceGroupName = $rgName
                        VNetName          = $vnetName
                        SubnetName        = $subnet.SubnetName
                        Action            = "Added"
                        Reason            = "Subnet added to existing VNet"
                    }
                }
                else {
                    $results += [PSCustomObject]@{
                        Environment       = $environment
                        ResourceGroupName = $rgName
                        VNetName          = $vnetName
                        SubnetName        = $subnet.SubnetName
                        Action            = "Skipped"
                        Reason            = "Subnet already exists"
                    }

                    Write-Host "SUBNET EXISTS: $($subnet.SubnetName)"
                }
            }

            if ($vnetChanged) {
                $existingVnet | Set-AzVirtualNetwork -ErrorAction Stop | Out-Null
            }
        }
    }
    catch {
        $results += [PSCustomObject]@{
            Environment       = $environment
            ResourceGroupName = $rgName
            VNetName          = $vnetName
            SubnetName        = ""
            Action            = "Failed"
            Reason            = $_.Exception.Message
        }

        Write-Warning "Failed processing VNet: $vnetName. $($_.Exception.Message)"
    }
}

$results | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "VNet and subnet automation completed."
Write-Host "Results exported to: $OutputPath"