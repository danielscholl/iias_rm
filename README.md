# Lab Directions

### Lab Jump Box

#### Create a Virtual Jump Box Machine using the Portal

- __Type:__ Visual Studio Community 2015 Update 3 with Azure SDK 2.9 on Windows Server 2012 R2  
- __Name:__  LABVM  
- __User Name:__  demo  
- __Password:__ <your_password>  
- __Resource Group:__ OPSLABRG  
- __Location:__ South Central US  
- __Size:__ D1 Standard


#### Disable IE Enhanced Security

Log into the Jump box and disable IE Enhance security using Powershell as Admin


```powershell
function Disable-ieESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}
Disable-ieESC

SetExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

#### Copy Lab Files to the JumpBox for use.

Log into the Jump box and create a directory @ C:\training and extract lab files to them.

> [https://github.com/danielscholl/iias_rm/](https://github.com/danielscholl/iias_rm)


#### Ensure PowerShell Azure RM Scripts are installed.

Install using Web Platform Installer the PowerShell Commands
> [http://aka.ms/webpi-azps](http://aka.ms/webpi-azps)



#### Start Windows PowerShell IDE and setup for azure access

```powershell
Login-AzureRmAccount
Get-AzureRmSubscription
Select-AzureRmSubscription -Subscriptionid ${id}
Save-AzureRmProfile -Path C:\training/Profile.json
```


#### Create Virtual Network

Using the Azure Portal Create a new Virtual Network with the following settings

- __Name:__ OpsTrainingVNET  
- __Address Space:__ 10.0.0.0/16  
- __SubNet Name:__ Apps  
- __SubNet Address Range:__ 10.0.0.0/24  
- __Resource Group:__ OpsVnetRmRG  
- __Location:__ South Central US  

> While creating ensure a new Subnet is created as well.

- __Name:__ Data
- __Address Range:__ 10.0.1.0/24



#### Create a Resource Group with a Storage Account

Using Windows PowerShell IDE create a Resource Group and Storage Accuont

> Execute: _create-azure-rg-storage.ps1_

- __Name:__ OpsVMRmRG  
- __Storage:__ opsvmstorage  
- __SKU:__ Standard_LRS  
- __Location:__ South Central US


#### Create WebVM-1 

Using the Azure Portal create a Virtual Server

- __Type:__ Windows Server 2012 R2 DataCenter  
- __Name:__ WebVM-1  
- __User Name:__ demo  
- __Password:__ <your_password>  
- __Resource Group:__ OpsVMRmRG  
- __Location:__ South Central US  
- __Size:__ DS1 Standard  
- __Network:__ OpsTrainingVNET  
- __Subnet:__ Apps  
- __Apps network Security Group:__ AppsNSG  
- __Inbound Rule:__  Inbound HTTP Priority 100 (Allow)  
- __Availability:__ WebAVSet  


#### Create WebVM-2

Using Windows PowerShell IDE create a Virtual Server

> Execute: _create-azure-vm-web.ps1_

- __Type:__ Windows Server 2012 R2 DataCenter  
- __Name:__ WebVM-2  
- __User Name:__ demo  
- __Password:__ <your_password>  
- __Resource Group:__ OpsVMRmRG  
- __Location:__ South Central US  
- __Size:__ DS1 Standard 


#### Create SQLVM-1

Using Windows PowerShell IDE create a Virtual Server

> Execute: _create-azure-vm-sql.ps1_

- __Type:__ Windows Server 2012 R2 DataCenter  
- __Name:__ SQLVM-2  
- __User Name:__ demo  
- __Password:__ <your_password>  
- __Resource Group:__ OpsVMRmRG  
- __Location:__ South Central US  
- __Size:__ DS1 Standard 