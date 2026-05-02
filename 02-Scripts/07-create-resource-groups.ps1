param(
    [string]$CsvPath = ".\03-CSV-Templates\resource-groups.csv"
)

# CloudSchool - Create Azure Resource Groups
# Purpose: Create standard Prod and Dev resource groups with tags

$ResourceGroups = Import-Csv $CsvPath

foreach ($rg in $ResourceGroups) {

    try {
        $ExistingRG = Get-AzResourceGroup -Name $rg.Name -ErrorAction Stop

        Write-Host "SKIP: Resource group already exists - $($rg.Name)"
    }
    catch {
        try {
            $CreatedRG = New-AzResourceGroup `
                -Name $rg.Name `
                -Location $rg.Location `
                -Tag @{
                    Environment = $rg.Environment
                    Project     = "CloudSchool"
                } `
                -ErrorAction Stop

            Write-Host "CREATED: Resource group - $($CreatedRG.ResourceGroupName)"
        }
        catch {
            Write-Host "FAILED: Resource group - $($rg.Name)"
            Write-Host $_.Exception.Message
        }
    }
}