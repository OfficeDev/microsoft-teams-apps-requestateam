<#
.SYNOPSIS
    Updates the Azure AD app secret used in Request-a-team. This script should be used once a new secret has been created in the App registrations blade.  

.DESCRIPTION
    Updates the following components of Request-a-team to use the updated secret - 

    Key vault - The 'appsecret' secret in the key vault is updated to use the new secret value. The previous version of the secret is disabled.
    Key vault API Connection - The requestateam-kv API Connection is redeployed using the new secret value. 

    PLEASE DESTROY THE COPIED SECRET VALUE ONCE SCRIPT EXECUTION HAS COMPLETED SUCCESSFULLY. 

.PARAMETER ClientId
    Id of the Request-a-team Azure AD app. Can be obtained trough the app registrations blade. 

.PARAMETER ClientSecret
    New secret value which has been generated.

.PARAMETER SubscriptionId
    Azure subscription id where request-a-team is deployed.

.PARAMETER Location
    Azure region where request-a-team is deployed.

.PARAMETER ResourceGroupName
    Name of the resource group where request-a-team is deployed.

.PARAMETER TenantId
    Id of the tenant. 

.PARAMETER KeyVaultName
    Name of the key vault that was used for the request-a-team deployment. 

.EXAMPLE
    refreshclientsecret.ps1 -ClientId "xxxxxxxx-xxxx-xxx-xxxxxxxxxxx" -ClientSecret "xxxxxxxx-xxxx-xxx-xxxxxxxxxxx" 
    -SubscriptionId 7ed1653b-228c-4d26-a0c0-2cd164xxxxxx -Location "westus" -TenantId "xxxxxxxx-xxxx-xxx-xxxxxxxxxxx" -ResourceGroupName "teamsgovernanceapp-rg" -KeyVaultName "requestateam-kv"

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


# Parameters
Param(
    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $ClientId,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $ClientSecret,

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
    $TenantId,

    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
    [String]
    $KeyVaultName

)

Write-Host "Launching Azure sign-in..." -ForegroundColor Yellow
$azConnect = Connect-AzAccount -Subscription $SubscriptionId -Tenant $TenantId

Write-Host "Launching Azure CLI sign-in..." -ForegroundColor Yellow
$cliLogin = az login
Write-Host "Connected to Azure" -ForegroundColor Green

Write-Host "Updating secret value in key vault" -ForegroundColor Yellow
$currSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name "appsecret"

# Create a new version of the secret - this will be enabled by default
$secretValue = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name "appsecret" -SecretValue $secretValue

# Disable previous version
Update-AzKeyVaultSecret -VaultName $KeyVaultName -Name "appsecret" -Version $currSecret.Version -Enable 0

Write-Host "Key vault secret value updated" -ForegroundColor Green

Write-Host "Updating Key Vault API connection..." -ForegroundColor Yellow

az deployment group create --resource-group $resourceGroupName --subscription $SubscriptionId --template-file 'keyvault.json' --parameters "subscriptionId=$SubscriptionId" "tenantId=$TenantId" "appId=$ClientId" "appSecret=$ClientSecret" "location=$Location" "keyvaultName=$KeyVaultName"

Write-Host "Updated Key Vault API connection" -ForegroundColor Green
