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
