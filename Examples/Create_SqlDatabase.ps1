<#
    Configuration creates Azure SQL Database
#>
configuration CreateSqlDatabase 
{
    param
    (
        $workingDirectory,
        $name,
        $serverCredential,
        $serverName,
        $ruleName,
        $startIPAddress,
        $endIPAddress,
        $azureSubscriptionName,
        $azurePublishSettingsFile
    )

    Import-DscResource -Name 
    Import-DscResource -Name 
    Import-DscResource -Name 

    # Verify working directory
    if ((test-path $workingDirectory) -eq $false) 
    {
        Write-Warning 'The working directory does not exist.  Exiting script.'
        Exit
    }

    node localhost 
    {

         MSDN
        {
            Ensure = 'Present'
            AzureSubscriptionName = $azureSubscriptionName
            AzurePublishSettingsFile = $azurePublishSettingsFile
        }
        
        ServerFirewallRule firewallRule 
        {
		    RuleName = $ruleName		
            ServerName = $serverName    
		    StartIPAddress = $startIPAddress
		    EndIPAddress = $endIPAddress
            DependsOn = '[]MSDN'
	    }

	     sqlDatabase 
        {
		    Name = $name
		    ServerCredential = $serverCredential
		    ServerName = $serverName
            MaximumSizeInGB = 1
            DependsOn = '[ServerFirewallRule]firewallRule'
	    }

        #LocalConfigurationManager 
        #{ 
            #CertificateId = $node.Thumbprint 
        #} 

    }
}

$script:configData = 
@{  
    AllNodes = @(       
                    @{    
                        NodeName = "localhost"  
                        Role = "TestHost"  
                        #CertificateFile = Join-Path $workingdir 'publicKey.cer'
                        #Thumbprint = ''
                         
                    };  
                );      
}  

#Sample use (please change values of parameters according to your scenario):
$workingDirectory = 'C:\test'
$azureSubscriptionName = 'Visual Studio Ultimate with MSDN'
$azurePublishSettingsFile = Join-Path $workingDirectory 'visual.publishsettings'
$name = "databaseName"
$securePassword = ConvertTo-SecureString "P@ssword" -AsPlainText -Force
$serverCredential = New-Object System.Management.Automation.PSCredential ("mylogin", $securePassword)
$serverName = "serverName"
$ruleName = "ruleName"
$startIPAddress = "111.111.111.111"
$endIPAddress = "111.111.111.111"

CreateSqlDatabase -configurationData $script:configData -workingDirectory $workingDirectory `
                  -azureSubscriptionName $azureSubscriptionName -azurePublishSettingsFile $azurePublishSettingsFile `
                  -name $name -serverCredential $serverCredential -serverName $serverName -ruleName $ruleName `
                  -startIPAddress $startIPAddress -endIPAddress $endIPAddress
