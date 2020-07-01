<#
.SYNOPSIS
    Deploys the following assets of the Teams Automate solution - 

        -SharePoint Site
        -Azure AD App Registration
        -Azure Automation Account & Runbooks
        -Logic App

.DESCRIPTION
    Deploys the Teams Automate solution (excluding the PowerApp and Flows).
    This script uses the Azure CLI, Azure Az PowerShell and SharePoint PnP PowerShell to perform the deployment.

    As part of the deployment, the script will grant admin consent for the Azure AD App to the required Graph permissions. 

    The script requires input during execution, requires sign-in to a number of services and therefore should be monitored.

    The following section details the required parameters.

    To see this in a PowerShell session use Get-Help -Full 

.PARAMETER TenantName
    Name of the tenant to deploy to (excluding onmicrosoft.com) e.g. contoso

.PARAMETER RequestsSiteName
    Name of the SharePoint site to store the requests, can include spaces (URL/Alias auomatically generated). If the site exists, it will prompt to overwrite and will apply the provisioning template.

.PARAMETER RequestsSiteDesc
    Description for the site that will be created above.

.PARAMETER ManagedPath
    Managed path configured in the tenant e.g. 'sites' or 'teams' (no forward slash).

.PARAMETER SubscriptionId
    Azure subscription id to deploy the solution to.

.PARAMETER Location
    Azure region to deploy the resources to (see below table - internal name should be used e.g. uksouth.

.PARAMETER ResourceGroupName
    A name for a new resource group to deploy the solution to - the script will create this resoure group.

.PARAMETER AppName
    Name for the Azure ad app that will be created.

.PARAMETER ServiceAccountUPN
    UPN of Service Account to be used for the solution - used in the Logic App connections to connect to SharePoint, Outlook and Microsoft Teams.

.PARAMETER UseMSGraphBeta
    Deploys a version of the provisioning logic app which uses solely the beta endpoint for the Microsoft Graph (provides the ability to create private channels when cloning teams and creating teams from your own defined templates). Otherwise the 1.0 endpoint will be used.

.PARAMETER IsEdu
    Specifies whether the current tenant is an Education tenant. If set to true, the Education Teams Templates will be deployed. These will be skipped if set to false or left blank.

.EXAMPLE
    deploy.ps1 -TenantName "contoso" -RequestsSiteName "Teams Request" -RequestsSiteDesc "Site to Microsoft Teams requests" 
    -ManagedPath "sites" -SubscriptionId "acb9bcbb-1f4b-44b9-960c-7ddaf4ad21d2" -Location "uksouth" -ResourceGroupName "teamsautomate-rg" -AppName "TeamsAutomate" -ServiceAccountUPN provisioning@contoso.com -UseMSGraphBeta $false -IsEdu $false

-----------------------------------------------------------------------------------------------------------------------------------
Script name : deploy.ps1
Authors : Alex Clark (SharePoint PFE, Microsoft)
Version : 1.0
Dependencies :
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:     Info:
-----------------------------------------------------------------------------------------------------------------------------------
DISCLAIMER
   THIS CODE IS SAMPLE CODE. THESE SAMPLES ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.
   MICROSOFT FURTHER DISCLAIMS ALL IMPLIED WARRANTIES INCLUDING WITHOUT LIMITATION ANY IMPLIED WARRANTIES
   OF MERCHANTABILITY OR OF FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK ARISING OUT OF THE USE OR
   PERFORMANCE OF THE SAMPLES REMAINS WITH YOU. IN NO EVENT SHALL MICROSOFT OR ITS SUPPLIERS BE LIABLE FOR
   ANY DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS, BUSINESS
   INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR OTHER PECUNIARY LOSS) ARISING OUT OF THE USE OF OR
   INABILITY TO USE THE SAMPLES, EVEN IF MICROSOFT HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
   BECAUSE SOME STATES DO NOT ALLOW THE EXCLUSION OR LIMITATION OF LIABILITY FOR CONSEQUENTIAL OR
   INCIDENTAL DAMAGES, THE ABOVE LIMITATION MAY NOT APPLY TO YOU.
#>

<# Valid Azure locations

DisplayName          Latitude    Longitude    Name
-------------------  ----------  -----------  ------------------
East Asia            22.267      114.188      eastasia
Southeast Asia       1.283       103.833      southeastasia
Central US           41.5908     -93.6208     centralus
East US              37.3719     -79.8164     eastus
East US 2            36.6681     -78.3889     eastus2
West US              37.783      -122.417     westus
North Central US     41.8819     -87.6278     northcentralus
South Central US     29.4167     -98.5        southcentralus
North Europe         53.3478     -6.2597      northeurope
West Europe          52.3667     4.9          westeurope
Japan West           34.6939     135.5022     japanwest
Japan East           35.68       139.77       japaneast
Brazil South         -23.55      -46.633      brazilsouth
Australia East       -33.86      151.2094     australiaeast
Australia Southeast  -37.8136    144.9631     australiasoutheast
South India          12.9822     80.1636      southindia
Central India        18.5822     73.9197      centralindia
West India           19.088      72.868       westindia
Canada Central       43.653      -79.383      canadacentral
Canada East          46.817      -71.217      canadaeast
UK South             50.941      -0.799       uksouth
UK West              53.427      -3.084       ukwest
West Central US      40.890      -110.234     westcentralus
West US 2            47.233      -119.852     westus2
Korea Central        37.5665     126.9780     koreacentral
Korea South          35.1796     129.0756     koreasouth
France Central       46.3772     2.3730       francecentral
France South         43.8345     2.1972       francesouth
Australia Central    -35.3075    149.1244     australiacentral
Australia Central 2  -35.3075    149.1244     australiacentral2
South Africa North   -25.731340  28.218370    southafricanorth
South Africa West    -34.075691  18.843266    southafricawest

#>

# Parameters
Param(
    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $TenantName,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $TenantId,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $RequestsSiteName,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $RequestsSiteDesc,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $ManagedPath,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $SubscriptionId,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $Location,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $ResourceGroupName,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $AppName,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $ServiceAccountUPN,

    [Parameter(Mandatory = $false,
        ValueFromPipeline = $true)]
    [Bool]
    $UseMSGraphBeta = $false,

    [Parameter(Mandatory = $false,
        ValueFromPipeline = $true)]
    [Bool]
    $IsEdu = $false
)

Add-Type -AssemblyName System.Web

# Check for presence of Azure CLI
If (-not (Test-Path -Path "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2")) {
    Write-Host "AZURE CLI NOT INSTALLED!`nPLEASE INSTALL THE CLI FROM https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest and re-run this script in a new PowerShell session" -ForegroundColor Red
    break
}

# Install required modules
Install-Module microsoft.online.sharepoint.powershell -Scope CurrentUser
Install-Module SharePointPnPPowerShellOnline -Scope CurrentUser -MinimumVersion 3.19.2003.0 -Force
Install-Module ImportExcel -Scope CurrentUser
Install-Module Az -AllowClobber -Scope CurrentUser
Install-Module AzureADPreview -Scope CurrentUser
Install-Module WriteAscii -Scope CurrentUser

# Variables
$packageRootPath = "..\"
$templatePath = "Templates\teamsautomate-sitetemplate.xml"
$settingsPath = "Scripts\Settings\SharePoint List items.xlsx"

#  Worksheet
$siteRequestSettingsWorksheetName = "Request Settings"
$teamsTemplatesWorksheetName = "Teams Templates"

#  lists
$requestsListName = "Teams Requests"
$requestSettingsListName = "Team Request Settings"
$teamsTemplatesListName = "Teams Templates"

#  Field names
$TitleFieldName = "Title"
$TeamNameFieldName = "Team Name"

$tenantUrl = "https://$tenantName.sharepoint.com"
$tenantAdminUrl = "https://$tenantName-admin.sharepoint.com"

# Remove any spaces in the site name to create the alias
$requestsSiteAlias = $RequestsSiteName -replace (' ', '')
$requestsSiteUrl = "https://$tenantName.sharepoint.com/$ManagedPath/$requestsSiteAlias"

# Automation account settings
$automationAccountName = "teamsautomate-auto"

# API connection names
$spoConnectionName = "teamsautomate-spo"
$o365OutlookConnectionName = "teamsautomate-o365outlook"
$o365UsersConnectionName = "teamsautomate-o365users"
$teamsConnectionName = "teamsautomate-teams"

# Global variables
$global:context = $null
$global:requestsListId = $null
$global:requestsSetingsListId = $null
$global:teamsTemplatesListId = $null
$global:appId = $null
$global:appSecret = $null
$global:appServicePrincipalId = $null
$global:siteClassifications = $null
$global:location = $null

# Create site and apply provisioning template
function CreateRequestsSharePointSite {
    try {
        Write-Host "### TEAMS REQUESTS SITE CREATION ###`nCreating Teams Requests SharePoint site..." -ForegroundColor Yellow

        $site = Get-PnPTenantSite -Url $requestsSiteUrl -ErrorAction SilentlyContinue

        if (!$site) {

            # Site will be created with current user connected to PnP as the owner/primary admin
            New-PnPSite -Type TeamSite -Title $RequestsSiteName -Alias $requestsSiteAlias -Description $RequestsSiteDesc

            Write-Host "Site created`n**TEAMS REQUESTS SITE CREATION COMPLETE**" -ForegroundColor Green
        }
        
            

        else {
            Write-Host "Site already exists! Do you wish to overwrite?" -ForegroundColor Red
            $overwrite = Read-Host " ( y (overwrite) / n (exit) )"
            if ($overwrite -ne "y") {
                break
            }
            
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error occured while creating of the SharePoint site: $errorMessage" -ForegroundColor Red
    }
}

# Configure the new site
function ConfigureSharePointSite {

    try {

        Write-Host "### REQUESTS SPO SITE CONFIGURATION ###`nConfiguring SharePoint site..." -ForegroundColor Yellow

        Write-Host "Applying provisioning template..." -ForegroundColor Yellow

        Apply-PnPProvisioningTemplate -Path (Join-Path $packageRootPath $templatePath) -ClearNavigation

        Write-Host "Applied template" -ForegroundColor Green

        $context = Get-PnPContext
        # Ensure Site Assets
        $web = $context.Web
        $context.Load($web)
        $context.Load($web.Lists)
        $context.ExecuteQuery()

        # Rename Title field
        $siteRequestsList = Get-PnPList $requestsListName
        $global:requestsListId = $siteRequestsList.Id
        $fields = $siteRequestsList.Fields
        $context.Load($fields)
        $context.ExecuteQuery()

        $titleField = $fields | Where-Object { $_.InternalName -eq $TitleFieldName }
        $titleField.Title = $TeamNameFieldName
        $titleField.UpdateAndPushChanges($true)
        $context.ExecuteQuery()

        # Adding settings in Site request Settings list
        $siteRequestsSettingsList = Get-PnPList $requestSettingsListName
        $context.Load($siteRequestsSettingsList)
        $context.ExecuteQuery()

        $siteRequestSettings = Import-Excel "$packageRootPath$settingsPath" -WorksheetName $siteRequestSettingsWorksheetName
        foreach ($setting in $siteRequestSettings) {
            if ($setting.Title -eq "TenantURL") {
                $setting.Value = $tenantUrl
            }
            if ($setting.Title -eq "SPOManagedPath") {
                $setting.Value = $ManagedPath
            }
            if ($setting.Title -eq "SiteClassifications") {
                $setting.Value = $global:siteClassifications
            }
            $listItemCreationInformation = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
            $newItem = $siteRequestsSettingsList.AddItem($listItemCreationInformation)
            $newitem["Title"] = $setting.Title
            $newitem["Description"] = $setting.Description
            # Hide site classifications option in Power App if no site classifications were found in the tenant
            if ($null -eq $global:siteClassifications -and $setting.Title -eq "HideSiteClassifications") {
                $newItem["Value"] = "true"
            }
            else {
                $newitem["Value"] = $setting.Value
            }
            $newitem.Update()
            $context.ExecuteQuery()

        }

        # Hide blocked words field in settings list
        $field = $siteRequestsSettingsList.Fields.GetByInternalNameOrTitle("BlockedWordsValue")
        $field.SetShowInEditForm($false)
        $context.ExecuteQuery()
        $field.SetShowInNewForm($false)
        $context.ExecuteQuery()
        $field.SetShowInDisplayForm($false)
        $context.ExecuteQuery()

        Write-Host "Added settings to Site Requests Settings list" -ForegroundColor Green

        # Adding templates to Teams Templates list
        $teamsTemplatesList = Get-PnPList $teamsTemplatesListName
        $context.Load($teamsTemplatesList)
        $context.ExecuteQuery()
        $global:teamsTemplatesListId = $teamsTemplatesList.Id

        $teamsTemplates = Import-Excel "$packageRootPath$settingsPath" -WorksheetName $teamsTemplatesWorksheetName
        foreach ($template in $teamsTemplates) {
            If (!$isEdu -and ($template.BaseTemplateId -eq "educationStaff" -or $template.BaseTemplateId -eq "educationProfessionalLearningCommunity")) {
                # Tenant is not an EDU tenant  - do nothing
            }
            else {
                $listItemCreationInformation = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
                $newItem = $teamsTemplatesList.AddItem($listItemCreationInformation)
                $newItem["Title"] = $template.Title
                $newItem["BaseTemplateType"] = $template.BaseTemplateType
                $newItem["BaseTemplateId"] = $template.BaseTemplateId
                $newItem["TeamId"] = $template.TeamId
                $newItem["Description"] = $template.Description
                $newItem["FirstPartyTemplate"] = $template.FirstPartyTemplate
                $newItem["TeamVisibility"] = $template.TeamVisibility
                $newitem.Update()
                $context.ExecuteQuery()
            }
        }
        Write-Host "Added templates to Teams Templates list" -ForegroundColor Green

        Write-Host "Adding Service Account to Owners group" -ForegroundColor Yellow

        # Check if service account already exists in the site (service account is the same user that is authenticated to PnP)
        $user = Get-PnPUser | Where-Object Email -eq $ServiceAccountUPN

        if ($null -eq $user) {
            # Get owners group
            $group = Get-PnPGroup | Where-Object Title -Match "Owners"
            
            # Add service account to owners group
            Add-PnPUserToGroup -LoginName $ServiceAccountUPN -Identity $group
        }

        Write-Host "Finished configuring site" -ForegroundColor Green

    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error occured while configuring the SharePoint site: $errorMessage" -ForegroundColor Red
    }
}

# Get configured site classifications
function GetSiteClassifications {
    $groupDirectorySetting = Get-AzureADDirectorySetting | Where-Object DisplayName -eq "Group.Unified"
    $classifications = $groupDirectorySetting.Values | Where-Object Name -eq "ClassificationList" | Select-Object Value

    $global:siteClassifications = $classifications.Value
}

# Gets the azure ad app
function GetAzureADApp {
    param ($appName)

    $app = az ad app list --display-name $appName | ConvertFrom-Json

    return $app

}

function CreateAzureADApp {
    try {
        Write-Host "### AZURE AD APP CREATION ###" -ForegroundColor Yellow

        # Check if the app already exists - script has been previously executed
        $app = GetAzureADApp $appName

        if (-not ([string]::IsNullOrEmpty($app))) {

            # Update azure ad app registration using CLI
            Write-Host "Azure AD App '$appName' already exists - updating existing app..." -ForegroundColor Yellow

            az ad app update --id $app.appId --required-resource-accesses './manifest.json' --password $global:appSecret

            Write-Host "Waiting for app to finish updating..."

            Start-Sleep -s 60

            Write-Host "Updated Azure AD App" -ForegroundColor Green

        } 
        else {
            # Create the app
            Write-Host "Creating Azure AD App - '$appName'..." -ForegroundColor Yellow

            # Create azure ad app registration using CLI
            az ad app create --display-name $appName --required-resource-accesses './manifest.json' --password $global:appSecret --end-date '2299-12-31T11:59:59+00:00'

            Write-Host "Waiting for app to finish creating..."

            Start-Sleep -s 60
            
            Write-Host "Created Azure AD App" -ForegroundColor Green

        }

        $app = GetAzureADApp $appName
        $global:appId = $app.appId

        Write-Host "Granting admin content for Microsoft Graph..." -ForegroundColor Yellow

        # Grant admin consent for app registration required permissions using CLI
        az ad app permission admin-consent --id $global:appId
        
        Write-Host "Waiting for admin consent to finish..."

        Start-Sleep -s 60
        
        Write-Host "Granted admin consent" -ForegroundColor Green

        # Get service principal id for the app we created
        $global:appServicePrincipalId = Get-AzADServicePrincipal -DisplayName $appName | Select-Object -ExpandProperty Id

        Write-Host "### AZURE AD APP CREATION FINISHED ###" -ForegroundColor Green
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error occured while creating an Azure AD App: $errorMessage" -ForegroundColor Red
    }
}

# Create automation account, import modules, deploy runbooks and configure access policies
function DeployAutomationAssets {
    try {
        Write-Host "Creating and deploying automation assets..." -ForegroundColor Yellow

        $automationAccount = Get-AzAutomationAccount | Where-Object AutomationAccountName -eq $automationAccountName

        if ($null -ne $automationAccount) {
            #Automation account already exists - script has been previously executed
            #Delete the automation account and recreate
            Write-Host "Automation account already exists - deleting..." -ForegroundColor Yellow

            Remove-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $ResourceGroupName -Force
            
            Write-Host "Automation account deleted" -ForegroundColor Green
            
        }
        
        Write-Host "Creating automation account..." -ForegroundColor Yellow

        New-AzAutomationAccount -Name $automationAccountName -Location $global:location -ResourceGroupName $ResourceGroupName

        Write-Host "Finished creating automation account" -ForegroundColor Green

        # TODO - Make content links into variables
        # Import automation modules - wait for each module to import before continuing 

        Write-Host "Importing automation modules..." -ForegroundColor Yellow

        New-AzAutomationModule -AutomationAccountName $automationAccountName -Name "Az.Accounts" -ContentLink "https://devopsgallerystorage.blob.core.windows.net/packages/az.accounts.1.6.2.nupkg" -ResourceGroupName $ResourceGroupName

        while ((Get-AzAutomationModule -Name "Az.Accounts" -ResourceGroupName $ResourceGroupName -AutomationAccountName $automationAccountName).ProvisioningState -eq "Creating") {
            Start-Sleep -Seconds 30
        }
               
        New-AzAutomationModule -AutomationAccountName $automationAccountName -Name "SharePointPnPPowerShellOnline" -ContentLink "https://devopsgallerystorage.blob.core.windows.net/packages/sharepointpnppowershellonline.3.12.1908.1.nupkg" -ResourceGroupName $ResourceGroupName

        Write-Host "Finished importing automation modules" -ForegroundColor Green

        Write-Host "Importing and publishing runbooks..." -ForegroundColor Yellow

        # Import automation runbooks
        Import-AzAutomationRunbook -Name "CheckSiteExists" -Path "./runbooks/checksiteexists.ps1" `
            -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName `
            -Type PowerShell

        # Publish runbooks
        Publish-AzAutomationRunbook -Name "CheckSiteExists" -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName

        Write-Host "Finished importing and publishing runbooks" -ForegroundColor Green

        Write-Host "Creating automation variables..." -ForegroundColor Yellow

        # Create variables
        New-AzAutomationVariable -AutomationAccountName $automationAccountName -Name "appClientId" -Encrypted $False -Value $global:appId -ResourceGroupName $ResourceGroupName
        New-AzAutomationVariable -AutomationAccountName $automationAccountName -Name "appSecret" -Encrypted $true -Value $global:appSecret -ResourceGroupName $ResourceGroupName

        Write-Host "Finished creating automation variables" -ForegroundColor Green

        Write-Host "Creating role assignments..." -ForegroundColor Yellow

        # Create the role assignments
        New-AzRoleAssignment -ObjectId $global:appServicePrincipalId -RoleDefinitionName "Automation Job Operator" -ResourceName $automationAccountName -ResourceType Microsoft.Automation/automationAccounts -ResourceGroupName $ResourceGroupName
        New-AzRoleAssignment -ObjectId $global:appServicePrincipalId -RoleDefinitionName "Automation Runbook Operator" -ResourceName $automationAccountName -ResourceType Microsoft.Automation/automationAccounts -ResourceGroupName $ResourceGroupName

        Write-Host "Finished creating role assignments" -ForegroundColor Green
        
        Write-Host "Finished automation assets deployment" -ForegroundColor Green

    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error occured while deploying Azure resources: $errorMessage" -ForegroundColor Red
    }

}

# Deploy ARM template - currently only used for the logic app
function DeployARMTemplate {
    try { 
        # Deploy ARM templates
        Write-Host "Deploying api connections..." -ForegroundColor Yellow
        az deployment group create --resource-group $resourceGroupName --subscription $SubscriptionId --template-file 'connections.json' --parameters "subscriptionId=$subscriptionId" "tenantId=$TenantId" "appId=$global:appId" "appSecret=$global:appSecret" "location=$global:location"

        Write-Host "Deploying logic app..." -ForegroundColor Yellow

        if ($UseMSGraphBeta) {
            Write-Host "Microsoft Graph beta endpoint will be used"
            az deployment group create --resource-group $resourceGroupName --subscription $SubscriptionId --template-file 'processteamrequestbeta.json' --parameters "resourceGroupName=$resourceGroupName" "subscriptionId=$subscriptionId" "tenantId=$TenantId" "appId=$global:appId" "appSecret=$global:appSecret" "automationAccountName=$automationAccountName" "requestsSiteUrl=$requestsSiteUrl" "requestsListId=$global:requestsListId" "location=$global:location" "serviceAccountUPN=$ServiceAccountUPN"
        }
        else {
            az deployment group create --resource-group $resourceGroupName --subscription $SubscriptionId --template-file 'processteamrequestv1.0.json' --parameters "resourceGroupName=$resourceGroupName" "subscriptionId=$subscriptionId" "tenantId=$TenantId" "appId=$global:appId" "appSecret=$global:appSecret" "automationAccountName=$automationAccountName" "requestsSiteUrl=$requestsSiteUrl" "requestsListId=$global:requestsListId" "templatesListId=$global:teamsTemplatesListId" "location=$global:location" "serviceAccountUPN=$ServiceAccountUPN"
        }

        Write-Host "Finished deploying logic app" -ForegroundColor Green
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error occured while deploying Azure resources: $errorMessage" -ForegroundColor Red
    }
}

# Shows OAuth sign-in window
function ShowOAuthWindow {
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width = 600; Height = 800 }
    $web = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width = 580; Height = 780; Url = ($url -f ($Scope -join "%20")) }
    $docComp = {
        $Global:uri = $web.Url.AbsoluteUri
        if ($Global:Uri -match "error=[^&]*|code=[^&]*") { $form.Close() }
    }
    $web.Add_DocumentCompleted($docComp)
    $form.Controls.Add($web)
    $form.Add_Shown( { $form.Activate() })
    $form.ShowDialog() | Out-Null
}

function AuthoriseLogicAppConnection($resourceId) {
    $parameters = @{
        "parameters" = , @{
            "parameterName" = "token";
            "redirectUrl"   = "https://ema1.exp.azure.com/ema/default/authredirect"
        }
    }

    # Get the links needed for consent
    $consentResponse = Invoke-AzResourceAction -Action "listConsentLinks" -ResourceId $resourceId -Parameters $parameters -Force

    $url = $consentResponse.Value.Link 

    # Show sign-in prompt window and grab the code after auth
    ShowOAuthWindow -URL $url

    $regex = '(code=)(.*)$'
    $code = ($uri | Select-string -pattern $regex).Matches[0].Groups[2].Value
    # Write-output "Received an accessCode: $code"

    if (-Not [string]::IsNullOrEmpty($code)) {
        $parameters = @{ }
        $parameters.Add("code", $code)
        # NOTE: errors ignored as this appears to error due to a null response
    
        #confirm the consent code
        Invoke-AzResourceAction -Action "confirmConsentCode" -ResourceId $resourceId -Parameters $parameters -Force -ErrorAction Ignore
    }   

    # Retrieve the connection
    $connection = Get-AzResource -ResourceId $resourceId
    Write-Host "Connection " $connection.Name " now " $connection.Properties.Statuses[0]
}

function AuthoriseLogicAppConnections() {

    Write-Host "### LOGIC APP CONNECTIONS AUTHORISATION ###`nStarting authorisation for Logic App Connections`nPlease authenticate with the Service Account - $ServiceAccountUPN" -ForegroundColor Yellow
    $spoconnection = Get-AzResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $resourceGroupName -Name $spoConnectionName

    $o365OutlookConnection = Get-AzResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $resourceGroupName -Name $o365OutlookConnectionName

    $o365UsersConnection = Get-AzResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $resourceGroupName -Name $o365UsersConnectionName

    $teamsConnection = Get-AzResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $resourceGroupName -Name $teamsConnectionName

    Write-Host "SharePoint Connection"
    AuthoriseLogicAppConnection($spoConnection.ResourceId)
    Write-Host "Office 365 Outlook Connection"
    AuthoriseLogicAppConnection($o365OutlookConnection.ResourceId)
    Write-Host "Office 365 Users Connection"
    AuthoriseLogicAppConnection($o365UsersConnection.ResourceId)
    Write-Host "Microsoft Teams Connection"
    AuthoriseLogicAppConnection($teamsConnection.ResourceId)

    Write-Host "### LOGIC APP CONNECTIONS AUTHORISATION COMPLETE ###" -ForegroundColor Green
}

function CreateRoleAssignments() {

    Write-Host "### AZURE ROLE ASSIGNMENTS ###`nCreating Role Assignments..." -ForegroundColor Yellow

    # Create the role assignments
    New-AzRoleAssignment -ObjectId $global:appServicePrincipalId -RoleDefinitionName "Automation Job Operator" -ResourceName $automationAccountName -ResourceType Microsoft.Automation/automationAccounts -ResourceGroupName $ResourceGroupName
    New-AzRoleAssignment -ObjectId $global:appServicePrincipalId -RoleDefinitionName "Automation Runbook Operator" -ResourceName $automationAccountName -ResourceType Microsoft.Automation/automationAccounts -ResourceGroupName $ResourceGroupName

    Write-Host "Role assignments created`n### AZURE ROLE ASSIGNMENTS COMPLETE ###" -ForegroundColor Green

}

#Check that the provided location is a valid Azure location
function ValidateAzureLocation {
    $locations = Get-AzLocation
    
    $global:location = $Location.Replace(" ", "").ToLower()

    # Validate that the location exists
    if ($null -eq ($locations | Where-Object Location -eq $global:location)) {
        throw "Invalid Azure Location. Please provide a valid location. See this list - https://azure.microsoft.com/en-gb/global-infrastructure/locations/"

    }
    
    # Validate that the region supports Azure automation (https://azure.microsoft.com/en-gb/global-infrastructure/services/?products=automation&regions=all)
    If (($global:location -eq "southafricawest") -or ($global:location -eq "australiacentral2") -or ($global:location -eq "southafricawest") -or ($global:location -eq "canadaeast") -or ($global:location -eq "chinaeast") -or ($global:location -eq "germanynorth") -or ($global:location -eq "southindia") `
            -or ($global:location -eq "westindia") -or ($global:location -eq "japaneast") -or ($global:location -eq "koreasouth") -or ($global:location -eq "switzerlandnorth") -or ($global:location -eq "switzerlandnwest") -or ($global:location -eq "uaecentral") -or ($global:location -eq "ukwest")) {
     
        throw "Azure location does not support Automation. See this list for regions which support Automation - https://azure.microsoft.com/en-gb/global-infrastructure/services/?products=automation&regions=all"
     
    }
    
}


Write-Ascii -InputObject "Request-a-Team" -ForegroundColor Magenta

Write-Host "### DEPLOYMENT SCRIPT STARTED ###" -ForegroundColor Magenta

#Write-Host "Enter desired App Password (Secret) for Azure AD App (at least 16 characters long, containing 1 special character and numeric character)" -ForegroundColor Yellow

# Generate base64 secret for the app
$guid = New-Guid

$global:appSecret = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($guid))))

#global:appSecret = Read-Host -AsSecureString

#$global:appSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($global:appSecret))

$global:encodedAppSecret = [System.Web.HttpUtility]::UrlEncode($global:appSecret) 

# Initialise connections - Azure Az/CLI
Write-Host "Launching Azure sign-in..." -ForegroundColor Yellow
$azConnect = Connect-AzAccount -Subscription $SubscriptionId -Tenant $TenantId
ValidateAzureLocation
Write-Host "Launching Azure AD sign-in..." -ForegroundColor Yellow
Connect-AzureAD
Write-Host "Launching Azure CLI sign-in..." -ForegroundColor Yellow
$cliLogin = az login
Write-Host "Connected to Azure" -ForegroundColor Green
# Connect to PnP
Write-Host "Launching PnP sign-in..." -ForegroundColor Yellow
$pnpConnect = Connect-PnPOnline -Url $tenantAdminUrl -UseWebLogin
Write-Host "Connected to SPO" -ForegroundColor Green

CreateAzureADApp
GetSiteClassifications
CreateRequestsSharePointSite
# Connect to the new site
$pnpConnect = Connect-PnPOnline $requestsSiteUrl -UseWebLogin
ConfigureSharePointSite

Write-Host "### AZURE RESOURCES DEPLOYMENT ###`nStarting Azure resources deployment..." -ForegroundColor Yellow

# Create resource group
# Handle spaces in resource group name
$ResourceGroupName = $ResourceGroupName.Replace(" ", "")
Write-Host "Creating resource group $resourceGroupName..." -ForegroundColor Yellow
New-AzResourceGroup -Name $resourceGroupName -Location $global:location
Write-Host "Created resource group" -ForegroundColor Green

DeployAutomationAssets
DeployARMTemplate

Write-Host "Azure resources deployed`n### AZURE RESOURCES DEPLOYMENT COMPLETE ###" -ForegroundColor Green

AuthoriseLogicAppConnections

Write-Host "DEPLOYMENT COMPLETED SUCCESSFULLY" -ForegroundColor Green