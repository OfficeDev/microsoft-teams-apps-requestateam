#Script to check if a site already exists in the tenant - checks active sites and deleted sites (tenant recycle bin)

[CmdletBinding()]
Param
(
    [Parameter (Mandatory = $true)]
    [String] $siteUrl
)

$appId = Get-AutomationVariable -Name "appClientId"
$appSecret = Get-AutomationVariable -Name "appSecret"
$tenantName = $siteUrl.Substring(0, $siteUrl.IndexOf(".")).Replace("https://", "")

try {
    #Connect to spo
    Connect-PnPOnline -Url "https://$tenantName-admin.sharepoint.com" -AppId $appId -AppSecret $appSecret

    #Check connection
    $context = Get-PnPContext
    if ($context) {
        Write-Verbose "Connected to SharePoint Online"

        #Get site from active site collections
        $site = Get-PnPTenantSite -Url $siteUrl
        
        #Get site from the site collection recycle bin
        $binItem = Get-PnPTenantRecycleBinItem | Where-Object Url -eq $siteUrl

        #Check to see if the active site or deleted site is not null
        if ($site -ne $null -or $binItem -ne $null) {
            #Site exists
            Write-Output $true
        }
        else {
            #Site does not exist
            Write-Output $false
        }
        
    }
    else {
        Write-Error "Issue connecting to SharePoint Online"
    }
}
catch {
    #Script error
    Write-Error "An error occured: $($PSItem.ToString())"
}