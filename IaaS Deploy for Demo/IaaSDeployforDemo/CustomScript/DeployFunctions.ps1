#
# tuServDeployFunctions.ps1
#
function Add-ADServiceAccounts
{
[CmdletBinding()]
param
(
$domain,
$serviceAccountOU,
$password
)

Write-Verbose -Verbose "Adding service accounts to Active Directory"
Write-Verbose -Verbose "---"

# build up the OU= parameter
$domainparts = $domain.Split(".")
$domainpartsjoined = $domainparts -join ",DC="
$serviceAccountOURoot = "DC=" + $domainpartsjoined

    $ou = new-adorganizationalunit -name $serviceAccountOU -path $serviceAccountOURoot
    $service_ou = "OU=" + $serviceAccountOU + "," +  $serviceAccountOURoot

    New-ADUser  -givenname "ADFS" -name "ADFS Service" -Surname "Service" -SamAccountName "svc_adfs" -UserPrincipalName ("svc_adfs@" + $domain) -DisplayName "ADFS Service" -Description "Service Account for ADFS" -Enabled $true -ChangePasswordAtLogon $false -AccountPassword (ConvertTo-SecureString -string $password -AsPlainText -force) -PasswordNeverExpires $true -Path $service_ou 
	New-ADUser  -givenname "tuServ" -name "tuServ Service" -Surname "Service" -SamAccountName "svc_tuserv" -UserPrincipalName ("svc_tuserv@" + $domain) -DisplayName "tuServ Service" -Description "Service Account for tuServ" -Enabled $true -ChangePasswordAtLogon $false -AccountPassword (ConvertTo-SecureString -string $password -AsPlainText -force) -PasswordNeverExpires $true -Path $service_ou 

}


function Add-ADComputerGroup
{
[CmdletBinding()]
param
(
$domain,
$serviceAccountOU
)

Write-Verbose -Verbose "Adding computer group to Active Directory"
Write-Verbose -Verbose "---"

# build up the OU= parameter
$domainparts = $domain.Split(".")
$domainpartsjoined = $domainparts -join ",DC="
$serviceAccountOURoot = "DC=" + $domainpartsjoined

    $service_ou = "OU=" + $serviceAccountOU + "," +  $serviceAccountOURoot

	New-ADGroup -Name "tuServ Computers" -SamAccountName tuServComputers -GroupCategory Security -GroupScope Global -DisplayName "tuServ Computers" -Path $service_ou -Description "Servers in this group are members of this tuServ environment"  


}

function Add-ADComputerGroupMember
{
[CmdletBinding()]
param
(
$group,
$member
)

Write-Verbose -Verbose "Adding $member to group $group in Active Directory"
Write-Verbose -Verbose "---"

	$ad_group = get-adgroup -filter * | where {$_.name -eq $group}
	Add-ADGroupMember $ad_group –Member $member


}


function Generate-NewCertificateTemplate
{
	[CmdletBinding()]
	# note can only be run on the server with PSPKI eg the ActiveDirectory domain controller
	param
	(
		$certificateTemplateName,
		$certificateSourceTemplateName		
	)

	Write-Verbose -Verbose "Generating New Certificate Template" 

		Import-Module .\PSPKI\pspki.psm1
		
		$certificateCnName = "CN="+$certificateTemplateName

		$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
		$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext" 

		$NewTempl = $ADSI.Create("pKICertificateTemplate", $certificateCnName) 
		$NewTempl.put("distinguishedName","$certificateCnName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext") 

		$NewTempl.put("flags","66113")
		$NewTempl.put("displayName",$certificateTemplateName)
		$NewTempl.put("revision","4")
		$NewTempl.put("pKIDefaultKeySpec","1")
		$NewTempl.SetInfo()

		$NewTempl.put("pKIMaxIssuingDepth","0")
		$NewTempl.put("pKICriticalExtensions","2.5.29.15")
		$NewTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.1")
		$NewTempl.put("pKIDefaultCSPs","2,Microsoft DH SChannel Cryptographic Provider, 1,Microsoft RSA SChannel Cryptographic Provider")
		$NewTempl.put("msPKI-RA-Signature","0")
		$NewTempl.put("msPKI-Enrollment-Flag","0")
		$NewTempl.put("msPKI-Private-Key-Flag","16842768")
		$NewTempl.put("msPKI-Certificate-Name-Flag","1")
		$NewTempl.put("msPKI-Minimal-Key-Size","2048")
		$NewTempl.put("msPKI-Template-Schema-Version","2")
		$NewTempl.put("msPKI-Template-Minor-Revision","2")
		$NewTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.287972.12774745.2574475.3035268.16494477.77.11347877.1740361")
		$NewTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.1")
		$NewTempl.SetInfo()

		$WATempl = $ADSI.psbase.children | where {$_.Name -eq $certificateSourceTemplateName}
		$NewTempl.pKIKeyUsage = $WATempl.pKIKeyUsage
		$NewTempl.pKIExpirationPeriod = $WATempl.pKIExpirationPeriod
		$NewTempl.pKIOverlapPeriod = $WATempl.pKIOverlapPeriod
		$NewTempl.SetInfo()
		
		$certTemplate = Get-CertificateTemplate -Name $certificateTemplateName
		Get-CertificationAuthority | Get-CATemplate | Add-CATemplate -Template $certTemplate | Set-CATemplate

#objectClass                          : {top, pKICertificateTemplate}
#cn                                   : {Copy of Web Server}
#distinguishedName                    : {CN=Copy of Web Server,CN=Certificate Templates,CN=Public Key
#                                       Services,CN=Services,CN=Configuration,DC=ts10,DC=local}
#instanceType                         : {4}
#whenCreated                          : {2/20/2015 3:00:57 PM}
#whenChanged                          : {2/20/2015 3:00:57 PM}
#displayName                          : {Copy of Web Server}
#uSNCreated                           : {System.__ComObject}
#uSNChanged                           : {System.__ComObject}
#showInAdvancedViewOnly               : {True}
#nTSecurityDescriptor                 : {System.__ComObject}
#name                                 : {Copy of Web Server}
#objectGUID                           : {131 44 45 225 102 139 101 64 184 100 64 183 202 25 92 28}
#flags                                : {131649}
#revision                             : {100}
#objectCategory                       : {CN=PKI-Certificate-Template,CN=Schema,CN=Configuration,DC=ts10,DC=local}
#pKIDefaultKeySpec                    : {1}
#pKIKeyUsage                          : {160 0}
#pKIMaxIssuingDepth                   : {0}
#pKICriticalExtensions                : {2.5.29.15}
#pKIExpirationPeriod                  : {0 128 114 14 93 194 253 255}
#pKIOverlapPeriod                     : {0 128 166 10 255 222 255 255}
#pKIExtendedKeyUsage                  : {1.3.6.1.5.5.7.3.1}
#pKIDefaultCSPs                       : {2,Microsoft DH SChannel Cryptographic Provider, 1,Microsoft RSA SChannel
#                                       Cryptographic Provider}
#dSCorePropagationData                : {1/1/1601 12:00:00 AM}
#msPKI-RA-Signature                   : {0}
#msPKI-Enrollment-Flag                : {0}
#msPKI-Private-Key-Flag               : {16842768}
#msPKI-Certificate-Name-Flag          : {1}
#msPKI-Minimal-Key-Size               : {2048}
#msPKI-Template-Schema-Version        : {2}
#msPKI-Template-Minor-Revision        : {2}
#msPKI-Cert-Template-OID              : {1.3.6.1.4.1.311.21.8.287972.12774745.2574475.3035268.16494477.77.11347877.17403
#                                       61}
#msPKI-Certificate-Application-Policy : {1.3.6.1.5.5.7.3.1}
#AuthenticationType                   : Secure#

}

function Set-tsCertificateTemplateAcl
{
	[CmdletBinding()]
	param
	(
	$certificateTemplate,
	$computers
	)

	Write-Verbose -Verbose "Setting ACL for cert $certificateTemplate to allow $computers"
	Write-Verbose -Verbose "---"

		Import-Module .\PSPKI\pspki.psm1
		
		Write-Verbose -Verbose "Adding group $computers to acl for cert $certificateTemplate"
		Get-CertificateTemplate -Name $certificateTemplate | Get-CertificateTemplateAcl | Add-CertificateTemplateAcl -User $computers -AccessType Allow -AccessMask Read, Enroll | Set-CertificateTemplateAcl

}


function Generate-SSLCertificate
{
	[CmdletBinding()]
	param
	(
	$certificateSubject,
	$certificateTemplate
	)

	Write-Verbose -Verbose "Creating SSL cert using $certificateTemplate for $certificateSubject"
	Write-Verbose -Verbose "---"
	
	Import-Module .\PSPKI\pspki.psm1

	Write-Verbose -Verbose "Generating Certificate (Single)"
		$certificateSubjectCN = "CN=" + $certificateSubject
		# Version #1
		$powershellCommand = "& {get-certificate -Template " + $certificateTemplate + " -CertStoreLocation Cert:\LocalMachine\My -DnsName " + $certificateSubject + " -SubjectName " + $certificateSubjectCN + " -Url ldap:}"
		Write-Verbose -Verbose $powershellCommand
		$bytes = [System.Text.Encoding]::Unicode.GetBytes($powershellCommand)
		$encodedCommand = [Convert]::ToBase64String($bytes)

		Start-Process -wait "powershell.exe" -ArgumentList "-encodedcommand $encodedCommand"
}

function Export-SSLCertificate
{
	[CmdletBinding()]
	param
	(
	$certificateSubject,
	$certificateExportFile,
	$certificatePassword
	)

	Write-Verbose -Verbose "Exporting cert $certificateSubject to $certificateExportFile with password $certificatePassword"
	Write-Verbose -Verbose "---"

	Import-Module .\PSPKI\pspki.psm1

	Write-Verbose -Verbose "Exporting Certificate (Single)"
	
		$password = ConvertTo-SecureString $certificatePassword -AsPlainText -Force
		Get-ChildItem Cert:\LocalMachine\My | where {$_.subject -match $certificateSubject -and $_.Subject -ne $_.Issuer} | Export-PfxCertificate -FilePath $certificateExportFile -Password $password

}

function Import-SSLCertificate {
	[CmdletBinding()]
	param
	(
		$certificateFileName,
		$certificatePassword
	)	

		Write-Verbose -Verbose "Importing cert $certificateFileName with password $certificatePassword"
		Write-Verbose -Verbose "---"

		Import-Module .\PSPKI\pspki.psm1

		Write-Verbose -Verbose "Attempting to import certificate" $certificateFileName
		# import it
		$password = ConvertTo-SecureString $certificatePassword -AsPlainText -Force
		Import-PfxCertificate –FilePath ($certificateFileName) cert:\localMachine\my -Password $password

}

function Create-ADFSFarm
{
[CmdletBinding()]
param
(
$domainCredential,
$adfsName, 
$adfsDisplayName, 
$adfsCredentials,
$certificateSubject
)

	Write-Verbose -Verbose "In Function Create-ADFS Farm"
	Write-Verbose -Verbose "Parameters:"
	Write-Verbose -Verbose "adfsName: $adfsName"
	Write-Verbose -Verbose "certificateSubject: $certificateSubject"
	Write-Verbose -Verbose "adfsDisplayName: $adfsDisplayName"
	Write-Verbose -Verbose "adfsCredentials: $adfsCredentials"
	Write-Verbose -Verbose "============================================"

	Write-Verbose -Verbose "Importing Module"
	Import-Module ADFS
	Write-Verbose -Verbose "Getting Thumbprint"
	$certificateThumbprint = (get-childitem Cert:\LocalMachine\My | where {$_.subject -match $certificateSubject} | Sort-Object -Descending NotBefore)[0].thumbprint
	Write-Verbose -Verbose "Thumprint is $certificateThumbprint"
	Write-Verbose -Verbose "Install ADFS Farm"

	Write-Verbose -Verbose "Echo command:"
	Write-Verbose -Verbose "Install-AdfsFarm -credential $domainCredential -CertificateThumbprint $certificateThumbprint -FederationServiceDisplayName '$adfsDisplayName' -FederationServiceName $adfsName -ServiceAccountCredential $adfsCredentials"
	Install-AdfsFarm -credential $domainCredential -CertificateThumbprint $certificateThumbprint -FederationServiceDisplayName "$adfsDisplayName" -FederationServiceName $adfsName -ServiceAccountCredential $adfsCredentials -OverwriteConfiguration

}

function Set-WapConfiguration
{
[CmdletBinding()]
Param(
$credential,
$fedServiceName,
$certificateSubject
)

Write-Verbose -Verbose "Configuring WAP Role"
Write-Verbose -Verbose "---"

	#$certificate = (dir Cert:\LocalMachine\My | where {$_.subject -match $certificateSubject}).thumbprint
	$certificateThumbprint = (get-childitem Cert:\LocalMachine\My | where {$_.subject -match $certificateSubject} | Sort-Object -Descending NotBefore)[0].thumbprint

	# install WAP
	Install-WebApplicationProxy –CertificateThumbprint $certificateThumbprint -FederationServiceName $fedServiceName -FederationServiceTrustCredential $credential

}

function Add-HostsFileEntry
{
[CmdletBinding()]
	param
	(
		$ip,
		$domain
	)

	$hostsFile = "$env:windir\System32\drivers\etc\hosts"
	$newHostEntry = "`t$ip`t$domain";

		if((gc $hostsFile) -contains $NewHostEntry)
		{
			Write-Verbose -Verbose "The hosts file already contains the entry: $newHostEntry.  File not updated.";
		}
		else
		{
			Add-Content -Path $hostsFile -Value $NewHostEntry;
		}
}

function Get-RedirectedUrl  
{  
	[CmdletBinding()]
	param
	(
		[string]$url
	)

    $request = [System.Net.WebRequest]::Create($url) 
    $request.AllowAutoRedirect = $false 
    $response = $request.GetResponse() 
    $redirectedurl = ($response | where StatusCode -eq "Found" | % {$_.GetResponseHeader("Location")} )
	return $redirectedurl
} 
