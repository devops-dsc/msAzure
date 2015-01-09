############################################################
# DSC Azure Test Example - REMOVE VMS
#
# This script removes specific VMs from Azure
#
# This script is DESTRUCTIVE without a method of restoration
#
# The subscription must be in place in order to access Azure
# and do work, so if this is being run in a new PS session
# you might have to first apply the SetupSubscription.ps1
# script first.
# 

# INSTANCE - use this identifier to select the instance
[CmdletBinding()]
param(
[Parameter(Mandatory,ValueFromPipeline)][string]$Instance,
[switch]$Force
)

# Set the folder where your files will live
$workingdir = split-path $myinvocation.mycommand.path

$SetupSubscription = Join-Path $workingdir 'SetupSubscription.ps1'
& $SetupSubscription

# DSC Configuration
Configuration DestroyAzureTestVMs
{
    Import-DscResource -Module xAzure

    Node $AllNodes.NodeName 
    {

        # List of VM's to Destroy

         TestVM1
        {
            Ensure = 'Absent'
            Name = 'TestVM1'
            ServiceName = $Node.ServiceName
            StorageAccountName = $Node.StorageAccountName
            ImageName = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201404.01-en.us-127GB.vhd'
        }
         TestVM2
        {
            Ensure = 'Absent'
            Name = 'TestVM2'
            ServiceName = $Node.ServiceName
            StorageAccountName = $Node.StorageAccountName
            ImageName = 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201404.01-en.us-127GB.vhd'
        }
    }
}

$ConfigData=    @{ 
    AllNodes = @(     
                    @{  
                        NodeName = 'localhost'
                        StorageAccountName = "testvmstorage$Instance"
                        ServiceName = "testvmservice$Instance"
                    }
                )
}

# Create MOF
DestroyAzureTestVMs -OutputPath $workingdir -ConfigurationData $ConfigData

if ($Force -eq $True) {$Safety = 'DESTROY'}
else {
Write-Host ""
Write-Warning "ARE YOU SURE YOU WANT TO DESTROY THE VMS INCLUDING VHD FILES"
$Safety = Read-Host "If you are certin please type DESTROY any other response will abort"
}

Switch ($Safety) {
    'DESTROY' {
        # Apply MOF
        Start-DscConfiguration -ComputerName 'localhost' -wait -force -verbose -path $workingdir
    }
    Default {Exit}
    }
