$ErrorActionPreference = 'Stop'
Select-AzureRmProfile -Path "$PSScriptRoot\OpsTraining.json"

# Deployment specific variables 
$location   = "southcentralus"
$saName     = "opsvmstorage"

Write-Host "Applying the PowerShell Custom Script for the data tier." -ForegroundColor Green
<# The PUblish-AzureRMDscConfiguration cmdlet packages the script and any dependencies into a .zip file 
and uploads to Azure Storage.

In this example the web-dsc-config.ps1 script installs IIS, and deploys a web app.
THe -AdditonalPath parameter is a simple method of packaging up additional content with the script.
#>


Publish-AzureRmVMDscConfiguration -ResourceGroupName $rgName `
                                  -ConfigurationPath "$PSScriptRoot\web-dsc-config.ps1" `
                                  -StorageAccountName $saName `
                                  -AdditionalPath "$PSScriptRoot\CloudShop" `
                                  -Force

<# THe Set-AzureRMDscExtension cmdlet take the packaged .zip file from Azure storage
and deploys it to the virtual machine specified with -ResourceGroupName and -VMname.
#>

Write-Host "Applying the PowerShell Custom Script for the web tier." -ForegroundColor Green

# You can run this cmdlet multiple time (poll) to wath the status of the extension)
Get-AzureRMVMDscExtension -ResourceGroupName $rgName -VMName $vmName -Name "WebDSCExt"


