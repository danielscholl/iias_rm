$ErrorActionPreference = 'Stop'

# SQLVM-1 specific variables 
$pubName    = "MicrosoftSQLServer"
$offerName  = "SQL2014SP1-WS2012R2"
$skuName    = "Web"
$nicName    = "sqlVMNIC1"
$vmName     = "SQLVM-1"
$vmSize     = "Standard_D1"

# Deployment specific variables 
$location   = "southcentralus"
$rgName     = "OpsVMRmRG"
$rgVNETName = "OpsVNETRmRG" 
$VNETName   = "OpsTrainingVNET"
$saName     = "opsvmstorage"  

$cred = Get-Credential -Message "Enter Admin Credentials"



Write-Host "Getting Existing Resources from resource group $rgName" -ForegroundColor Green

# Get the existing storage account  
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName `
                                        -Name $saName

$blobEndpoint = $storageAcc.PrimaryEndpoints.Blob.ToString()


# Get a reference to the existing virtual network 
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgVNETName `
                                  -Name $VNETName   




Write-Host "Creating new resources for VM $vmName" -ForegroundColor Green

# Create a new network interface in the Data subnet .Subnets[1].Id
$nic = New-AzureRmNetworkInterface -Name $nicName `
                                 -ResourceGroupName $rgName `
                                 -Location $location `
                                 -SubnetId $vnet.Subnets[1].Id 

# Create a new virtual machine configuration object
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize


# Associate the network interface with the VM 
Add-AzureRmVMNetworkInterface -Id $nic.Id -VM $vm

# Create the URI for data disk 1
$dataDiskName = "sqlvm1-datadisk1" 
$dataDiskUri = $blobEndpoint + "vhds/" + $dataDiskName  + ".vhd"

# Attach data disk 1 to the VM configuration
Add-AzureRmVMDataDisk -Name $dataDiskName `
                      -VhdUri $dataDiskUri -Caching None `
                      -DiskSizeInGB 1023 -Lun 0 -CreateOption empty `
                      -VM $vm

# Create the URI for data disk 2
$dataDiskName = "sqlvm1-datadisk2" 
$dataDiskUri = $blobEndpoint + "vhds/" + $dataDiskName  + ".vhd"

# Attach data disk 2 to the VM configuration 
Add-AzureRmVMDataDisk -Name $dataDiskName `
                      -VhdUri $dataDiskUri -Caching None `
                      -DiskSizeInGB 1023 -Lun 1 -CreateOption empty `
                      -VM $vm


# Set the local administrative credentials 
Set-AzureRmVMOperatingSystem -Windows `
                             -ComputerName $vmName `
                             -Credential $cred `
                             -ProvisionVMAgent  `
                             -VM $vm

# Set the source image 
Set-AzureRmVMSourceImage -PublisherName $pubName `
                         -Offer $offerName `
                         -Skus $skuName `
                         -Version "latest" `
                         -VM $vm

# Create the URI to the OS disk of the SLQ server
$osDiskName = "sqlvm1-osdisk0"
$osDiskUri    = $blobEndpoint + "vhds/" + $osDiskName  + ".vhd"

# Set the OS disk on the VM configuration object
Set-AzureRmVMOSDisk -Name $osDiskName `
                    -VhdUri $osDiskUri `
                    -CreateOption fromImage `
                    -VM $vm




Write-Host "Creating virtual machine $vmName" -ForegroundColor Green

$vm.DiagnosticsProfile


# Create the VM 
New-AzureRmVM -ResourceGroupName $rgName `
                -Location $location `
                -VM $vm