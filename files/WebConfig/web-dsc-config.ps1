Configuration Main
{

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node "localhost"
{

	# Install the IIS role 
	WindowsFeature IIS 
	{ 
		Ensure          = "Present" 
		Name            = "Web-Server" 
	} 
	# Install the ASP .NET 4.5 role 
	WindowsFeature AspNet45 
	{ 
		Ensure          = "Present" 
		Name            = "Web-Asp-Net45" 
	}
	# Install Web Management Tools
	WindowsFeature WebServerManagementConsole
    {
        Name = "Web-Mgmt-Console"
        Ensure = "Present"
    }
	   
	File WebContent 
	{ 
		Ensure          = "Present" 
		SourcePath      = "$PSScriptRoot\Contoso"
		DestinationPath = "C:\Inetpub\wwwroot"
		Recurse         = $true 
		Type            = "Directory" 
		DependsOn       = "[WindowsFeature]IIS" 
	} 
  }
}