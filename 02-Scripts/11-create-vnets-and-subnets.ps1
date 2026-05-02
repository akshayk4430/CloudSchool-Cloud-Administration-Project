param (
    [string]$CsvPath = ".\03-CSV-Templates\vnets.csv"
)

# Load CSV
$vnets = Import-Csv $CsvPath

# Group by VNet
$vnetGroups = $vnets | Group-Object VNetName

foreach ($group in $vnetGroups) {

    $vnetData = $group.Group[0]

    $vnetName = $vnetData.VNetName
    $rgName   = $vnetData.ResourceGroupName
    $location = $vnetData.Location
    $address  = $vnetData.AddressSpace

    # Check if VNet exists
    $existingVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

    if (-not $existingVnet) {

        Write-Host "CREATING VNET: $vnetName"

        $subnets = @()

        foreach ($subnet in $group.Group) {
            $subnets += New-AzVirtualNetworkSubnetConfig -Name $subnet.SubnetName -AddressPrefix $subnet.SubnetPrefix
        }

        New-AzVirtualNetwork 
            -Name $vnetName 
            -ResourceGroupName $rgName 
            -Location $location 
            -AddressPrefix $address 
            -Subnet $subnets

    } else {

        Write-Host "VNET EXISTS: $vnetName"

        foreach ($subnet in $group.Group) {

            $existingSubnet = $existingVnet.Subnets | Where-Object { $_.Name -eq $subnet.SubnetName }

            if (-not $existingSubnet) {

                Write-Host "ADDING SUBNET: $(Microsoft.Azure.Commands.Network.Models.PSSubnet.SubnetName)"

                Add-AzVirtualNetworkSubnetConfig 
                    -Name $subnet.SubnetName 
                    -AddressPrefix $subnet.SubnetPrefix 
                    -VirtualNetwork $existingVnet | Out-Null

                $existingVnet | Set-AzVirtualNetwork

            } else {
                Write-Host "SUBNET EXISTS: $(Microsoft.Azure.Commands.Network.Models.PSSubnet.SubnetName)"
            }
        }
    }
}
