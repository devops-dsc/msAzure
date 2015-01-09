############################################################
# DSC Azure Test Example - Status
#
# This script will show the detailed status of the  Virtual
# Machine in Azure.
#
# Before running this script, do the following:
#   * Open PowerShell and run Get-AzurePublishSettingsFile
#   * Download the .publishsettings file in to $workingdir
#

# INSTANCE - use this identifier to add more test environments
# If you are only adding VM's and don't need a new full environment,
# you only need to add another VM section to this script and run
# it again.
param(
[string]$InstanceID,
[switch]$ConnectionFiles
)

$Status = @()

$VMlist = Get-AzureVM | ? {$_.ServiceName -like "*$InstanceID"}
foreach ($VM in $VMlist) {

    $VMName = $VM.Name
    $ServiceName = $VM.ServiceName

    # Set the folder where your files will live
    $workingdir = split-path $myinvocation.mycommand.path
    if ((test-path $workingdir) -eq $false) {
        Write-Warning 'The working directory does not exist.  Exiting script.'
        Exit
        }

    $VMStatus = get-azurevm -name $VMName -servicename $ServiceName
    $fqdn = $ServiceName+'.cloudapp.net'

    $VMDetails = "" | Select CloudServiceName, VirtualMachineName, VirtualMachineIP, RemoteDesktopPort, PowerShellRemotePort, VirtualMachineStatus, GuestAgentStatus, ResourceExtensionStatus
    $VMDetails.CloudServiceName = $fqdn
    $VMDetails.VirtualMachineName = $VMName
    $VMDetails.VirtualMachineIP = $VMStatus.IpAddress
    $VMDetails.RemoteDesktopPort = Get-AzureEndpoint -VM $VMStatus | ? Name -eq RDP | % Port
    $VMDetails.PowerShellRemotePort = Get-AzureEndpoint -VM $VMStatus | ? Name -eq WinRmHTTPs | % Port
    $VMDetails.VirtualMachineStatus = $($VMStatus.Status)
    $VMDetails.GuestAgentStatus = $VMStatus.GuestAgentStatus.Status
    $VMDetails.ResourceExtensionStatus = $VMStatus.ResourceExtensionStatusList.ExtensionSettingStatus.Status

    $Status += $VMDetails

    if ($ConnectionFiles -eq $true -AND ($VM.vm.configurationsets.inputendpoints | % name) -contains 'RDP') {
        write-host "Downloading RDP File to WorkingDir"
        # include this line to automatically download the RDP file for a VM if available
        $VMFolder = if (!(test-path $workingdir\$VMName)) {mkdir $workingdir\$VMName}
        $RDP = Get-AzureRemoteDesktopFile -ServiceName $ServiceName -Name $VMName -LocalPath (Join-Path $workingdir\$VMName 'Connect.rdp')
        }

    if ($ConnectionFiles -eq $true -AND ($VM.vm.configurationsets.inputendpoints | % name) -contains 'WinRmHTTPs') {
        write-host "Installing certificate in local user store, to trust PowerShell endpoint."
        $Cert = Get-AzureCertificate -ServiceName $ServiceName -Thumbprint $VMStatus.VM.DefaultWinRmCertificateThumbprint -ThumbprintAlgorithm sha1
        $VMFolder = if (!(test-path $workingdir\$VMName)) {mkdir $workingdir\$VMName}
        $CertData = Join-Path $workingdir\$VMName Localhost.cert
        $Cert.data | out-file $CertData
        $CertResult = Import-Certificate -FilePath $CertData -CertStoreLocation Cert:\CurrentUser\Root
        write-host `n
        write-host 'Creating ConnectTo-Demo.ps1 to simplify PS remote connection.'
        "Enter-PSSession -ComputerName $fqdn -Credential (get-credential) -Port $PSPort -UseSSL" | Out-File (join-path $workingdir\$VMName ConnectTo-FullAdmin.ps1)
        "Write-Host 'This script assumes you have setup the demo endpoint.' -ForeGroundColor Green;Enter-PSSession -ComputerName $fqdn -Credential (get-credential) -Port $PSPort -ConfigurationName Demo1EP -UseSSL" | Out-File (join-path $workingdir\$VMName ConnectTo-Demo.ps1)
        }
        $Status
}
