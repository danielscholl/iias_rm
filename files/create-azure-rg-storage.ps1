$ErrorActionPreference = 'Stop'


# Deployment specific variables 
$location   = "southcentralus"
$skuName    = "Standard_LRS"
$rgName     = "OpsVMRmRG"
$saName     = "opsvmstorage"

Write-Host "Creating new resources for Storage $saName" -ForegroundColor Green

# Create a new resource group
New-AzureRmResourceGroup -Name $rgName -Location $location

# Create a new storage account.
$storageAcc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Location $location -SkuName $skuName -Name $saName
$blobEndpoint = $storageAcc.PrimaryEndpoints.Blob.ToString()