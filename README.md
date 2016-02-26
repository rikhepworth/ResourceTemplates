<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Frikhepworth%2FResourceTemplates%2Fmaster%2FIaaSDeployforDemo%2FIaaSDeployforDemo%2FTemplates%2FDemoEnvironment.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>

# IaaS Environment Resource Template for Demos #
This project contains the files used in my session demo around Azure Resource Templates.
The deployment creates a three server environment containing the following Windows servers:
* *Domain Controller with Certificate Services*. This has no public-facing network connection.
* *ADFS server*. This has no public-facing network connection.
* *WAP server*. This has a public IP address and can be access from the internet.

The deployment shows a number of techniques fro deploying IaaS environments to Azure:
* Use of nested deployments to break down complex templates into manageable components, which can then be reused.
* Reconfiguration of resource, such as the virtual network, following key deployment steps. This approach is used to set the IP address of the newly configured Domain Controller to the DNS address of the vNet after configuration. It is also used to deploy VMs with dynamic IP addresses then convert them to static addresses afterwards.
* Use of DSC to configure Windows servers.
* Use of the CustomScript extension to perform actions that cannot easiliy be done with DSC.
* Use of template outputs and references to pass information between nested deployments.
