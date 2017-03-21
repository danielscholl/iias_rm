$ErrorActionPreference = 'Stop'

# WebVM-2 specific variables 
$pubName    = "MicrosoftWindowsServer"
$offerName  = "WindowsServer"
$skuName    = "2012-R2-Datacenter"
$ipName     = "WebVM-2"
$nicName    = "WebVMNIC2"
$vmName     = "WebVM-2"
$vmSize     = "Standard_DS1"
$nsgName    = "APPSNSG"
$avSet      = "WebAVSet"

# Deployment specific variables 
$location   = "southcentralus"
$rgName     = "OpsVMRmRG"   
$rgVNETName = "OpsVNETRmRG" 
$VNETName   = "OpsTrainingVNET"
$dnsName    = "dks-web"  
$saName     = "opsvmstorage"

$cred = Get-Credential -Message "Enter Admin Credentials"



Write-Host "Getting Existing Resources from resource group $rgName" -ForegroundColor Green

# Get the existing storage account  
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName `
                                        -Name $saName

$blobEndpoint = $storageAcc.PrimaryEndpoints.Blob.ToString()

# Get the existing availability set
$avSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName `
                                    -Name $avSet 

# Get a reference to the existing virtual network 
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rgVNETName `
                                  -Name $VNETName   

# Get a reference to the existing network security group 
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName `
                                       -Name $nsgName




Write-Host "Creating new resources for VM $vmName" -ForegroundColor Green

# Create a new public IP address
$pip = New-AzureRmPublicIpAddress -Name $ipName `
                                -ResourceGroupName $rgName `
                                -Location $location `
                                -AllocationMethod Dynamic `
                                -DomainNameLabel $dnsName  

# Create a new network interface in the Apps subnet .Subnets[0]
$nic = New-AzureRmNetworkInterface -Name $nicName `
                                 -ResourceGroupName $rgName `
                                 -Location $location `
                                 -SubnetId $vnet.Subnets[0].Id `
                                 -PublicIpAddressId $pip.Id `
                                 -NetworkSecurityGroupId $nsg.ID 

# Create a new virtual machine configuration object
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize `
                          -AvailabilitySetId $avSet.Id

# Associate the network interface with the VM 
Add-AzureRmVMNetworkInterface -Id $nic.Id -VM $vm


# Set the OS credentials
Set-AzureRmVMOperatingSystem -Windows `
                             -ComputerName $vmName `
                             -Credential $cred `
                             -ProvisionVMAgent `
                             -VM $vm

# Set the source image 
Set-AzureRmVMSourceImage -PublisherName $pubName `
                         -Offer $offerName `
                         -Skus $skuName `
                         -Version "latest" `
                         -VM $vm

# Set the OS disk location 
$osDiskName = "vm2-osdisk"
$osDiskUri    = $blobEndpoint + "vhds/" + $osDiskName  + ".vhd"

# Set the OS disk on the virtual machine configuration
Set-AzureRmVMOSDisk -Name $osDiskName `
                    -VhdUri $osDiskUri `
                    -CreateOption fromImage `
                    -VM $vm



Write-Host "Creating virtual machine $vmName" -ForegroundColor Green

# Create the virtual machine 
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm
