#
# DomainController.ps1
#
param (
	$vmAdminUsername,
	$vmAdminPassword,
	$fsServiceName,
	$tsServiceName,
	$resourceLocation
)

$password =  ConvertTo-SecureString $vmAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:USERDOMAIN\$vmAdminUsername", $password)
Write-Verbose -Verbose "Entering Domain Controller Script"
Write-Verbose -verbose "Script path: $PSScriptRoot"
Write-Verbose -Verbose "vmAdminUsername: $vmAdminUsername"
Write-Verbose -Verbose "vmAdminPassword: $vmAdminPassword"
Write-Verbose -Verbose "fsServiceName: $fsServiceName"
Write-Verbose -Verbose "tsServiceName: $tsServiceName"
Write-Verbose -Verbose "env:UserDomain: $env:USERDOMAIN"
Write-Verbose -Verbose "resourceLocation: $resourceLocation"
Write-Verbose -Verbose "==================================="

	# Write an event to the event log to say that the script has executed.
	$event = New-Object System.Diagnostics.EventLog("Application")
	$event.Source = "AzureEnvironment"
	$info_event = [System.Diagnostics.EventLogEntryType]::Information
	$event.WriteEntry("DomainController Script Executed", $info_event, 5001)


Invoke-Command  -Credential $credential -ComputerName $env:COMPUTERNAME -ScriptBlock {

	param (
		$workingDir,
		$vmAdminPassword,
		$fsServiceName,
		$tsServiceName,
		$resourceLocation
	)
	# Working variables
	$serviceAccountOU = "Service Accounts"
	Write-Verbose -Verbose "Entering Domain Controller Script"
	Write-Verbose -verbose "workingDir: $workingDir"
	Write-Verbose -Verbose "vmAdminPassword: $vmAdminPassword"
	Write-Verbose -Verbose "fsServiceName: $fsServiceName"
	Write-Verbose -Verbose "tsServiceName: $tsServiceName"
	Write-Verbose -Verbose "env:UserDomain: $env:USERDOMAIN"
	Write-Verbose -Verbose "env:UserDNSDomain: $env:USERDNSDOMAIN"
	Write-Verbose -Verbose "env:ComputerName: $env:COMPUTERNAME"
	Write-Verbose -Verbose "resourceLocation: $resourceLocation"
	Write-Verbose -Verbose "==================================="


	# Write an event to the event log to say that the script has executed.
	$event = New-Object System.Diagnostics.EventLog("Application")
	$event.Source = "AzureEnvironment"
	$info_event = [System.Diagnostics.EventLogEntryType]::Information
	$event.WriteEntry("In DomainController scriptblock", $info_event, 5001)

	#go to our packages scripts folder
	Set-Location $workingDir
	
	$zipfile = $workingDir + "\PSPKI.zip"
	$destination = $workingDir
	[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
	[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $destination)

	Import-Module .\DeployFunctions.ps1

	#Enable CredSSP in server role for delegated credentials
	Enable-WSManCredSSP -Role Server –Force

	#Create OU for service accounts, computer group; create service accounts
	Add-ADServiceAccounts -domain $env:USERDNSDOMAIN -serviceAccountOU $serviceAccountOU -password $vmAdminPassword
	Add-ADComputerGroup -domain $env:USERDNSDOMAIN -serviceAccountOU $serviceAccountOU
	Add-ADComputerGroupMember -group "Environment Computers" -member ($env:COMPUTERNAME + '$')

	#Create new web server cert template
	$certificateTemplate = ($env:USERDOMAIN + "_WebServer")
	Generate-NewCertificateTemplate -certificateTemplateName $certificateTemplate -certificateSourceTemplateName "WebServer"
	Set-tsCertificateTemplateAcl -certificateTemplate $certificateTemplate -computers "EnvironmentComputers"

	# Generate SSL Certificates

	$fsCertificateSubject = $fsServiceName
	Generate-SSLCertificate -certificateSubject $fsCertificateSubject -certificateTemplate $certificateTemplate
	$tsCertificateSubject = $tsServiceName + ".northeurope.cloudapp.azure.com"
	Generate-SSLCertificate -certificateSubject $tsCertificateSubject -certificateTemplate $certificateTemplate

	# Export Certificates
	$fsCertExportFileName = $fsCertificateSubject+".pfx"
	$fsCertExportFile = $workingDir+"\"+$fsCertExportFileName
	Export-SSLCertificate -certificateSubject $fsCertificateSubject -certificateExportFile $fsCertExportFile -certificatePassword $vmAdminPassword
	$tsCertExportFileName = $tsCertificateSubject+".pfx"
	$tsCertExportFile = $workingDir+"\"+$tsCertExportFileName
	Export-SSLCertificate -certificateSubject $tsCertificateSubject -certificateExportFile $tsCertExportFile -certificatePassword $vmAdminPassword

	#Set permissions on the src folder
	$acl = Get-Acl c:\src
	$acl.SetAccessRuleProtection($True, $True)
	$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Domain Computers","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
	$acl.AddAccessRule($rule)
	$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
	$acl.AddAccessRule($rule)
	Set-Acl c:\src $acl


	#Create src folder to store shared files and copy certs to it
	Copy-Item -Path "$workingDir\*.pfx" c:\src

} -ArgumentList $PSScriptRoot, $vmAdminPassword, $fsServiceName, $tsServiceName, $resourceLocation

