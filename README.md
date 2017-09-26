# IaaS Environment Resource Template for Demos #

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Frikhepworth%2FResourceTemplates%2Fmaster%2FIaaSDeployforDemo%2FIaaSDeployforDemo%2FTemplates%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Frikhepworth%2FResourceTemplates%2Fmaster%2FIaaSDeployforDemo%2FIaaSDeployforDemo%2FTemplates%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This project contains the files used in my session demo around Azure Resource Templates.
The deployment creates a three server environment containing the following Windows servers:
* *Domain Controller with Certificate Services*. This has no public-facing network connection.
* *ADFS server*. This has no public-facing network connection.
* *WAP server*. This has a public IP address and can be access from the internet.

The deployment shows a number of techniques for deploying IaaS environments to Azure:
* Use of nested deployments to break down complex templates into manageable components, which can then be reused.
* Reconfiguration of resource, such as the virtual network, following key deployment steps. This approach is used to set the IP address of the newly configured Domain Controller to the DNS address of the vNet after configuration. It is also used to deploy VMs with dynamic IP addresses then convert them to static addresses afterwards.
* Use of DSC to configure Windows servers.
* Use of the CustomScript extension to perform actions that cannot easiliy be done with DSC.
* Use of template outputs and references to pass information between nested deployments.



# Web Site with Slots, SQL Elastic Pool with DBs #

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Frikhepworth%2FResourceTemplates%2Fmaster%2FWebSlotsSqlPools%2FWebSlotsSqlPools%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>

<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Frikhepworth%2FResourceTemplates%2Fmaster%2FWebSlotsSqlPools%2FWebSlotsSqlPools%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This project contains a tempkate to deploy the following services:
* SQL Azure Elastic Pool
* Two databases (one for production and one for staging)
* Azure App Serivces Web Site with a Staging Slots
* Connection Strings to both prod and staging on the web site

# Global Web Site with CDN. Traffic Manager, Redis, Cosmos DB deployed across multiple regions

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Frikhepworth%2FResourceTemplates%2Fmaster%2FGlobalWebSite%2FGlobalWebSite%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>

<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Frikhepworth%2FResourceTemplates%2Fmaster%2FGlobalWebSite%2FGlobalWebSite%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
# Web site, redis cache, CDN, traffic manager and cosmos DB #
This project contains a template to deploy the following services:
* Azure web site
* Redis Cache 
* Cosmos DB
* CDN
* Traffic Manager
Specifying multiple regions will create an app hosting plan, web site and redis cache in each region, connected to a traffic manager instance. Entering a single region will not deploy traffic manager (using the conditional function).
