# Create and configure a Windows Virtual Machine using Azure PowerShell in the Resource Manager deployment model

These steps show you how to construct a set of Azure PowerShell commands to create and configure an Azure virtual machine use it to study for a certification test.


## Step 1: Set your subscription

Login to your account.

	Login-AzureRmAccount

Get the available subscriptions by using the following command.

	Get-AzureRmSubscription | Sort SubscriptionName | Select SubscriptionName

Set your Azure subscription for the current session. Replace everything within the quotes, including the < and > characters, with the correct names.

	$subscr="<subscription name>"
	Select-AzureRmSubscription –SubscriptionName $subscr
	Get-AzureRmSubscription –SubscriptionName $subscr | Select-AzureRmSubscription

## Step 2: Create resources

In this section create each resource for your new virtual machine.

### Find Locations

Use this command to list available locations.

	(Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute).Locations |sort -Unique
	$location="<location name>"


### Resource group

Create a new resource group to use and put your resource in with these commands.

	$rgName="<resource group name>"
	$location="<location name>"
	$rg = New-AzureRmResourceGroup -Name $rgName -Location $location

Use this command to list your existing resource groups.

	Get-AzureRmResourceGroup | Sort ResourceGroupName | Select ResourceGroupName


### Virtual Network

Create as many subnets as needed into the Subnet Config Object

	$vnetName = "<Virtual Network Name>"
	$address = "<Address Prefix, such as 10.0.0.0/16"
	$snName = "<Subnet Name,such as Apps, Data"
	$snAddress = "<Subnet Address Prefix, such as 10.0.1.0/24, 10.0.2.0/24>"
	$subnets = @()
	$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name $snName -AddressPrefix $snAddress
	$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name $sn2Name -AddressPrefix $sn2Address
	$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgName -Location $location `
		-Name $vnetName -AddressPrefix $address -Subnet $subnets

Use this command to list your existing virtual networks.

	Get-AzureRmVirtualNetworks | Sort Name | Select Name


### Storage account

Test whether a chosen storage account name is globally unique.  
_**This Command is Classic and requires login to classic_

	Add-AzureAccount
	Test-AzureName -Storage <storage account name>

> "False" is unique

Create a new storage account for your new virtual machine with these commands.

	$rgName="<resource group name>"
	$location="<location name>"
	$saName="<storage account name>"
	$saType="<storage account type, specify one: Standard_LRS, Standard_GRS, Standard_RAGRS, or Premium_LRS>"
	$sa = New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName –Type $saType -Location $locName

Pick a globally unique name for your storage account __only lowercase letters and numbers__. 
Use this command to list the existing storage accounts.

	Get-AzureRmStorageAccount -ResourceGroupName $rgName |sort StorageAccountName |select StorageAccountName

Test whether a chosen storage account name is globally unique.

	Test-AzureName -Storage <storage account name>

> "False" is unique

### Network Security Group

Create Network Security Rules to be applied to the Network Security Group.

	$rules = @()
	$rules += New-AzureRmNetworkSecurityRuleConfig -Name "RDP" -Description "Allow inbound RDP connections." `
		-Access Allow -Direction Inbound -Priority 100  `
		-Protocol Tcp  `
		-SourceAddressPrefix "*" -SourcePortRange "*" `
		-DestinationAddressPrefix "*" -DestinationPort 3389
	$rules += New-AzureRmNetworkSecurityRuleConfig -Name "SSH" -Description "Allow inbound SSH connections." `
		-Access Allow -Direction Inbound -Priority 100  `
		-Protocol Tcp  `	
		-SourceAddressPrefix "*" -SourcePortRange "*" `
		-DestinationAddressPrefix "*" -DestinationPort 22

Create a Network Security Group Configuration

	$nsgName="<Network Security Group Name>"
	$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location `
		-Name $nsgName -SecurityRules $rules



### Create a Network Interface with a Public domain name and IP Address

The DNS Name can contain only letters, numbers, and hyphens but must start and end with a letter or number.

Test whether a chosen domain name is globally unique with these commands.

	$dnsName="<unique domain name>"
	$location="<location name>"
	Test-AzureRmDnsAvailability -DomainQualifiedName $dns -Location $loc

> "True" is unique

Create a Public IP Address for the VNET
	$ipName ="<public ip address name>"
	$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $location `
		-DomainNameLabel $dnsName -AllocationMethod Dynamic

Create a Network Interface for the Virtual Machine
	$nicName="<Network Interface Name>"
	$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location `
		-SubnetId $vnet.Subnets[0]Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id


### Availability set

Create a new availability set for the new virtual machine with these commands.

	$avName="<availability set name>"
	$rgName="<resource group name>"
	$locName="<location name>"
	$avSet = New-AzureRmAvailabilitySet –Name $avName –ResourceGroupName $rgName -Location $locName

> -PlatformUpdateDomainCount - default 5, maximum 20
> -PlatformFaultDomainCount - default 3, maximum 3

Use this command to list the existing availability sets.

	Get-AzureRmAvailabilitySet –ResourceGroupName $rgName | Sort Name | Select Name


### VM Config Set

Create a local VM Config object to be used and configured with settings such as NICs storage etc.

	$vmName="<virtual machine name>"
	$vmSize="<virtual machine size, such as: Standard_A1, Standard_D1_v2>"
	$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id


### Set the Virtual Machine Network Interface

Set the created NIC to the VM Config Objct

	$vm |Add-AzureRmVMNetworkInterface -Id $nic.Id


#### Set the Virtual Machine Image

Set a virtual machine Source Image and the OS Disk to the VM Config Object

	$pubName = "publisher, such as: MicrosoftWindowsServer, Canonical"
	$offerName = "offer, such as: WindowsServer, UbuntuServer"
	$skuName = "sku, such as: 2012-R2-Datacenter, 16.04-LTS"
	$vm | Set-AzureRmVMSourceImage -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"

> _** Publisher Offer and Sku can be retrieved using the following methods_ 
> __CLI(2.0)__ 
>	az vm image list -o table
> __PowerShell__ 
>	Get-AzureRmVMImagePublisher -Location -$location | select PublisherName
>	Get-AzureRmVMImageOffer -Location $location -PublisherName $publisher
>	Get-AzureRmVMImageSku -Location $location -PublisherName $publisher -Offer $offer


#### Set the Virtual Machine Disk(s)

Set a virtual machine OS Disk to the VM Config Object

	$blobEndPoint = $sa.PrimaryEndpoints.Blob.ToString()
	$osDisk1Name="<name of vhd in blob>"
	$osDisk1Uri = $blobEndpoint + "vhds/" + $osDiskName + ".vhd"
	$vm | Set-AzureRmVMOSDisk -Name $osDiskName -VhdUri $osDisk1Uri -CreateOption FromImage

Attach an existing VHD Disk in Blob Storage as a Data Disk to the VM Config Object

	$blobEndPoint = $sa.PrimaryEndpoints.Blob.ToString()
	$dataDisk1Name="<name of vhd in blob>"
	$dataDisk1Uri = $blobEndpoint + "vhds/" + $dataDisk1Name + ".vhd"
	$vm | Add-AzureRmVMDataDisk -Name $dataDisk1Name -VhdUri $dataDisk1Uri -Caching None -DiskSizeInGb 1023 -Lun 0 -CreateOption empty


#### Set the Login Credentials and OS TYPE

Set a credential object that stores the login information and the Operating System to the VM Config Object

	$vmName="<virtual machine name>"
	$cred = Get-Credential -Message "Enter Admin Credentials"
	$vm | Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred -ProvisionVMAgent
	$vm | Set-AzureRmVMOperatingSystem  -ComputerName $VMName -Linux -Credential $cred

> Parameter -Linux or -Windows to specify what type the credentials are, if Linux then no -ProvisionVMAgent option.



### Create the Virtual Machine

Using the VM config Object Create a virtual machine

	$vm | New-AzureRmVM -ResourceGroupName $rgName -Location $location 