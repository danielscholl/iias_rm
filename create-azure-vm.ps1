## Global
$ResourceGroupName = "532"
$Location = "southcentralus"
$Prefix = "<your_unique_prefix>"

## Storage
$StorageName = $Prefix.ToLower() + $ResourceGroupName.ToLower()
$StorageType = "Standard_LRS"

## Compute
$AVSetName = $Prefix + "-avset"
$VMName = $Prefix + "-vm1"
$VMSize = "Standard_A1"
$OSDiskName = $VMName + "-OSDisk"
$Publisher = "Canonical"
$Offer = "UbuntuServer"
$SKU = "16.04-LTS"

## Network Security Group
$NetworkSecurityGroupName = $ResourceGroupName + "-firewall"
$SSH_Port = 22

## Network
$InterfaceName = $VMName + "-nic-1"
$SubnetName = "Apps"
$VNetName = $ResourceGroupName + "-vnet"
$VNetAddressPrefix = "10.0.0.0/16"
$VNetSubnetAddressPrefix = "10.0.0.0/24"


# Resource Group
$ResourceGroup = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

# Storage
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -Type $StorageType -Location $Location

# Network Security Group
$Rules = @()
$Rules += New-AzureRmNetworkSecurityRuleConfig -Name "SSH" -Description "Allow Inbound SSH Connections." -Access Allow -Direction Inbound -Priority 100 -Protocol Tcp -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange $SSH_Port
$NSG = New-AzureRmNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName -Location $Location -SecurityRules $Rules

# Network
$Pip = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
$SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
$Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $Pip.Id

# Compute
$AVSet = New-AzureRmAvailabilitySet -Name $AVSetName -ResourceGroupName $ResourceGroupName -Location $Location

## Setup local VM object
$Credential = Get-Credential
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $AVSet.Id
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -ComputerName $VMName -Linux -Credential $Credential
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName $Publisher -Offer $Offer -Skus $SKU -Version "latest"
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage

## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine