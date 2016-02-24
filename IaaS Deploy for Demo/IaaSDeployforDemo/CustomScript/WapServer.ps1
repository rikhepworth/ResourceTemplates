#
# WapServer.ps1
#
param (
	$vmAdminUsername,
	$vmAdminPassword,
	$fsServiceName,
	$adfsServerName,
	$vmDCname,
	$resourceLocation
)

$password =  ConvertTo-SecureString $vmAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:USERDOMAIN\$vmAdminUsername", $password)

Write-Verbose -Verbose "Entering Domain Controller Script"
Write-Verbose -verbose "Script path: $PSScriptRoot"
Write-Verbose -Verbose "vmAdminUsername: $vmAdminUsername"
Write-Verbose -Verbose "vmAdminPassword: $vmAdminPassword"
Write-Verbose -Verbose "fsServiceName: $fsServiceName"
Write-Verbose -Verbose "adfsServerName: $adfsServerName"
Write-Verbose -Verbose "env:UserDomain: $env:USERDOMAIN"
Write-Verbose -Verbose "resourceLocation: $resourceLocation"
Write-Verbose -Verbose "==================================="


	# Write an event to the event log to say that the script has executed.
	$event = New-Object System.Diagnostics.EventLog("Application")
	$event.Source = "AzureEnvironment"
	$info_event = [System.Diagnostics.EventLogEntryType]::Information
	$event.WriteEntry("WAPserver Script Executed", $info_event, 5001)


	$srcPath = "\\"+ $vmDCname + "\src"
	$fsCertificateSubject = $fsServiceName
	$fsCertFileName = $fsCertificateSubject+".pfx"
	$certPath = $srcPath + "\" + $fsCertFileName

	#Copy cert from DC
	write-verbose -Verbose "Copying $certpath to $PSScriptRoot"
#		$powershellCommand = "& {copy-item '" + $certPath + "' '" + $workingDir + "'}"
#		Write-Verbose -Verbose $powershellCommand
#		$bytes = [System.Text.Encoding]::Unicode.GetBytes($powershellCommand)
#		$encodedCommand = [Convert]::ToBase64String($bytes)

#		Start-Process -wait "powershell.exe" -ArgumentList "-encodedcommand $encodedCommand"
		copy-item $certPath -Destination $PSScriptRoot -Verbose

Invoke-Command  -Credential $credential -ComputerName $env:COMPUTERNAME -ScriptBlock {

	param (
		$workingDir,
		$vmAdminPassword,
		$domainCredential,
		$adfsServerName,
		$fsServiceName,
		$vmDCname,
		$resourceLocation
	)
	# Working variables

	# Write an event to the event log to say that the script has executed.
	$event = New-Object System.Diagnostics.EventLog("Application")
	$event.Source = "AzureEnvironment"
	$info_event = [System.Diagnostics.EventLogEntryType]::Information
	$event.WriteEntry("In WAPserver scriptblock", $info_event, 5001)

	#go to our packages scripts folder
	Set-Location $workingDir
	
	$zipfile = $workingDir + "\PSPKI.zip"
	$destination = $workingDir
	[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
	[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $destination)
	
	Import-Module .\DeployFunctions.ps1

	$fsCertificateSubject = $fsServiceName
	$fsCertFileName = $workingDir + "\" + $fsCertificateSubject+".pfx"

	Write-Verbose -Verbose "Importing sslcert $fsCertFileName"
	Import-SSLCertificate -certificateFileName $fsCertFileName -certificatePassword $vmAdminPassword

	$fsIpAddress = (Resolve-DnsName $adfsServerName -type a).ipaddress
	Add-HostsFileEntry -ip $fsIpAddress -domain $fsCertificateSubject


	Set-WapConfiguration -credential $domainCredential -fedServiceName $fsCertificateSubject -certificateSubject $fsCertificateSubject


} -ArgumentList $PSScriptRoot, $vmAdminPassword, $credential, $adfsServerName, $fsServiceName, $vmDCname, $resourceLocation
