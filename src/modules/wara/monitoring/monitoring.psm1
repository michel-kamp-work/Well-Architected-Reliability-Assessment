using module ../utils/utils.psd1

# PowerShell classes for monitoring objects
class MonitoringConfigurationObj {
    [string]$ResourceId
    [string]$ResourceName
    [string]$ResourceType
    [string]$SubscriptionId
    [string]$ResourceGroupName
    [string]$Location
    [string]$ConfigurationType
    [string]$ConfigurationStatus
    [PSCustomObject]$Configuration
    [string]$Recommendation
    [string]$Impact
    [string]$Description
    [PSCustomObject]$Tags

    MonitoringConfigurationObj() {}

    MonitoringConfigurationObj([PSCustomObject]$Resource, [string]$ConfigType, [string]$Status, [PSCustomObject]$Config) {
        $this.ResourceId = $Resource.id
        $this.ResourceName = $Resource.name
        $this.ResourceType = $Resource.type
        $this.SubscriptionId = $Resource.subscriptionId
        $this.ResourceGroupName = $Resource.resourceGroup
        $this.Location = $Resource.location
        $this.ConfigurationType = $ConfigType
        $this.ConfigurationStatus = $Status
        $this.Configuration = $Config
        $this.Tags = $Resource.tags
        $this.SetRecommendation()
    }

    [void]SetRecommendation() {
        switch ($this.ConfigurationType) {
            'DiagnosticSettings' {
                if ($this.ConfigurationStatus -eq 'Missing') {
                    $this.Recommendation = 'Enable diagnostic settings to collect logs and metrics'
                    $this.Impact = 'High'
                    $this.Description = 'Resource does not have diagnostic settings configured, limiting observability'
                } else {
                    $this.Recommendation = 'Review diagnostic settings configuration'
                    $this.Impact = 'Medium'
                    $this.Description = 'Diagnostic settings are configured but may need optimization'
                }
            }
            'ApplicationInsights' {
                if ($this.ConfigurationStatus -eq 'Missing') {
                    $this.Recommendation = 'Configure Application Insights for application monitoring'
                    $this.Impact = 'High'
                    $this.Description = 'Application does not have Application Insights configured'
                } else {
                    $this.Recommendation = 'Review Application Insights configuration'
                    $this.Impact = 'Low'
                    $this.Description = 'Application Insights is configured'
                }
            }
            'MetricAlerts' {
                if ($this.ConfigurationStatus -eq 'Missing') {
                    $this.Recommendation = 'Configure metric alerts for proactive monitoring'
                    $this.Impact = 'High'
                    $this.Description = 'No metric alerts configured for this resource'
                } else {
                    $this.Recommendation = 'Review metric alert configuration'
                    $this.Impact = 'Low'
                    $this.Description = 'Metric alerts are configured'
                }
            }
            'ActivityLogAlerts' {
                if ($this.ConfigurationStatus -eq 'Missing') {
                    $this.Recommendation = 'Configure activity log alerts for operational awareness'
                    $this.Impact = 'Medium'
                    $this.Description = 'No activity log alerts configured'
                } else {
                    $this.Recommendation = 'Review activity log alert configuration'
                    $this.Impact = 'Low'
                    $this.Description = 'Activity log alerts are configured'
                }
            }
            default {
                $this.Recommendation = 'Review monitoring configuration'
                $this.Impact = 'Medium'
                $this.Description = 'General monitoring configuration review needed'
            }
        }
    }
}

<#
.SYNOPSIS
    Retrieves comprehensive monitoring configuration for Azure resources.

.DESCRIPTION
    The Get-WAFMonitoringConfiguration function queries multiple Azure monitoring services
    to provide a complete view of monitoring and observability configuration across resources.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.PARAMETER ResourceGroupNames
    An array of resource group names to filter the results.

.PARAMETER ResourceTypes
    An array of specific resource types to analyze.

.OUTPUTS
    Returns an array of MonitoringConfigurationObj objects representing monitoring configurations.

.EXAMPLE
    $monitoringConfig = Get-WAFMonitoringConfiguration -SubscriptionIds @('sub1', 'sub2')

.NOTES
    This function aggregates data from multiple monitoring-related functions.
#>
function Get-WAFMonitoringConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds,

        [Parameter(Mandatory = $false)]
        [string[]] $ResourceGroupNames = @(),

        [Parameter(Mandatory = $false)]
        [string[]] $ResourceTypes = @()
    )

    $monitoringObjects = @()

    # Repair subscription IDs to ensure proper format and extract GUIDs for Azure Resource Graph
    $repairedSubscriptionIds = Repair-WAFSubscriptionId -SubscriptionIds $SubscriptionIds
    $subscriptionGuids = $repairedSubscriptionIds | ForEach-Object { $_.replace('/subscriptions/', '') }

    # Get all resources to analyze
    $resources = Get-WAFAllResources -SubscriptionIds $subscriptionGuids -ResourceGroupNames $ResourceGroupNames -ResourceTypes $ResourceTypes

    # Analyze diagnostic settings
    $diagnosticSettings = Get-WAFDiagnosticSettings -SubscriptionIds $subscriptionGuids
    if ($diagnosticSettings.Count -gt 0) {
        $monitoringObjects += Test-WAFDiagnosticCoverage -Resources $resources -DiagnosticSettings $diagnosticSettings
    }

    # Analyze Application Insights
    $appInsights = Get-WAFApplicationInsightsConfiguration -SubscriptionIds $subscriptionGuids
    if ($appInsights.Count -gt 0) {
        $monitoringObjects += Test-WAFApplicationInsightsCoverage -Resources $resources -ApplicationInsights $appInsights
    }

    # Analyze metric alerts
    $metricAlerts = Get-WAFMetricAlerts -SubscriptionIds $subscriptionGuids
    if ($metricAlerts.Count -gt 0) {
        $monitoringObjects += Test-WAFMetricAlertCoverage -Resources $resources -MetricAlerts $metricAlerts
    }

    # Analyze activity log alerts
    $activityAlerts = Get-WAFActivityLogAlerts -SubscriptionIds $subscriptionGuids
    if ($activityAlerts.Count -gt 0) {
        $monitoringObjects += Test-WAFActivityLogAlertCoverage -Resources $resources -ActivityLogAlerts $activityAlerts
    }

    return $monitoringObjects
}

<#
.SYNOPSIS
    Retrieves all resources from specified subscriptions and resource groups.

.DESCRIPTION
    Helper function to get all Azure resources for monitoring analysis.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.PARAMETER ResourceGroupNames
    An array of resource group names to filter the results.

.PARAMETER ResourceTypes
    An array of specific resource types to analyze.

.OUTPUTS
    Returns an array of Azure resources.
#>
function Get-WAFAllResources {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds,

        [Parameter(Mandatory = $false)]
        [string[]] $ResourceGroupNames = @(),

        [Parameter(Mandatory = $false)]
        [string[]] $ResourceTypes = @()
    )

    $query = "Resources | project id, name, type, subscriptionId, resourceGroup, location, tags"

    if ($ResourceGroupNames.Count -gt 0) {
        $rgFilter = ($ResourceGroupNames | ForEach-Object { "'$_'" }) -join ', '
        $query += " | where resourceGroup in ($rgFilter)"
    }

    if ($ResourceTypes.Count -gt 0) {
        $typeFilter = ($ResourceTypes | ForEach-Object { "'$_'" }) -join ', '
        $query += " | where type in ($typeFilter)"
    }

    return Invoke-WAFQuery -Query $query -SubscriptionIds $SubscriptionIds
}

<#
.SYNOPSIS
    Retrieves Application Insights configurations across subscriptions.

.DESCRIPTION
    The Get-WAFApplicationInsightsConfiguration function queries Azure Resource Graph to retrieve
    all Application Insights instances and their configurations.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of Application Insights configurations.

.EXAMPLE
    $appInsights = Get-WAFApplicationInsightsConfiguration -SubscriptionIds @('sub1', 'sub2')
#>
function Get-WAFApplicationInsightsConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $query = @"
Resources
| where type == 'microsoft.insights/components'
| extend appType = properties.Application_Type
| extend workspaceId = properties.WorkspaceResourceId
| extend retentionInDays = properties.RetentionInDays
| extend samplingPercentage = properties.SamplingPercentage
| extend publicNetworkAccess = properties.publicNetworkAccessForIngestion
| extend publicNetworkAccessForQuery = properties.publicNetworkAccessForQuery
| project id, name, type, subscriptionId, resourceGroup, location, tags,
    appType, workspaceId, retentionInDays, samplingPercentage, 
    publicNetworkAccess, publicNetworkAccessForQuery
"@

    return Invoke-WAFQuery -Query $query -SubscriptionIds $SubscriptionIds
}

<#
.SYNOPSIS
    Retrieves Log Analytics workspaces across subscriptions.

.DESCRIPTION
    The Get-WAFLogAnalyticsWorkspaces function queries Azure Resource Graph to retrieve
    all Log Analytics workspaces and their configurations.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of Log Analytics workspace configurations.

.EXAMPLE
    $workspaces = Get-WAFLogAnalyticsWorkspaces -SubscriptionIds @('sub1', 'sub2')
#>
function Get-WAFLogAnalyticsWorkspaces {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $query = @"
Resources
| where type == 'microsoft.operationalinsights/workspaces'
| extend retentionInDays = properties.retentionInDays
| extend dailyQuotaGb = properties.workspaceCapping.dailyQuotaGb
| extend publicNetworkAccessForIngestion = properties.publicNetworkAccessForIngestion
| extend publicNetworkAccessForQuery = properties.publicNetworkAccessForQuery
| extend sku = properties.sku.name
| project id, name, type, subscriptionId, resourceGroup, location, tags,
    retentionInDays, dailyQuotaGb, publicNetworkAccessForIngestion, 
    publicNetworkAccessForQuery, sku
"@

    return Invoke-WAFQuery -Query $query -SubscriptionIds $SubscriptionIds
}

<#
.SYNOPSIS
    Retrieves diagnostic settings configurations.

.DESCRIPTION
    The Get-WAFDiagnosticSettings function queries Azure Resource Graph to retrieve
    diagnostic settings for resources that support them.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of diagnostic settings configurations.

.EXAMPLE
    $diagnosticSettings = Get-WAFDiagnosticSettings -SubscriptionIds @('sub1', 'sub2')
#>
function Get-WAFDiagnosticSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $query = @"
Resources
| where type == 'microsoft.insights/diagnosticsettings'
| extend targetResourceId = properties.resourceId
| extend workspaceId = properties.workspaceId
| extend storageAccountId = properties.storageAccountId
| extend eventHubAuthorizationRuleId = properties.eventHubAuthorizationRuleId
| extend logs = properties.logs
| extend metrics = properties.metrics
| project id, name, targetResourceId, workspaceId, storageAccountId, 
    eventHubAuthorizationRuleId, logs, metrics, subscriptionId, resourceGroup
"@

    return Invoke-WAFQuery -Query $query -SubscriptionIds $SubscriptionIds
}

<#
.SYNOPSIS
    Retrieves metric alert configurations.

.DESCRIPTION
    The Get-WAFMetricAlerts function queries Azure Resource Graph to retrieve
    all metric alerts and their configurations.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of metric alert configurations.

.EXAMPLE
    $metricAlerts = Get-WAFMetricAlerts -SubscriptionIds @('sub1', 'sub2')
#>
function Get-WAFMetricAlerts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $query = @"
Resources
| where type == 'microsoft.insights/metricalerts'
| extend enabled = properties.enabled
| extend severity = properties.severity
| extend evaluationFrequency = properties.evaluationFrequency
| extend windowSize = properties.windowSize
| extend targetResourceType = properties.targetResourceType
| extend scopes = properties.scopes
| extend actions = properties.actions
| extend criteria = properties.criteria
| project id, name, type, subscriptionId, resourceGroup, location, tags,
    enabled, severity, evaluationFrequency, windowSize, targetResourceType, 
    scopes, actions, criteria
"@

    return Invoke-WAFQuery -Query $query -SubscriptionIds $SubscriptionIds
}

<#
.SYNOPSIS
    Retrieves activity log alert configurations.

.DESCRIPTION
    The Get-WAFActivityLogAlerts function queries Azure Resource Graph to retrieve
    all activity log alerts and their configurations.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of activity log alert configurations.

.EXAMPLE
    $activityAlerts = Get-WAFActivityLogAlerts -SubscriptionIds @('sub1', 'sub2')
#>
function Get-WAFActivityLogAlerts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $query = @"
Resources
| where type == 'microsoft.insights/activitylogalerts'
| extend enabled = properties.enabled
| extend scopes = properties.scopes
| extend condition = properties.condition
| extend actions = properties.actions
| project id, name, type, subscriptionId, resourceGroup, location, tags,
    enabled, scopes, condition, actions
"@

    return Invoke-WAFQuery -Query $query -SubscriptionIds $SubscriptionIds
}

<#
.SYNOPSIS
    Retrieves action group configurations.

.DESCRIPTION
    The Get-WAFActionGroups function queries Azure Resource Graph to retrieve
    all action groups and their configurations.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of action group configurations.

.EXAMPLE
    $actionGroups = Get-WAFActionGroups -SubscriptionIds @('sub1', 'sub2')
#>
function Get-WAFActionGroups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $query = @"
Resources
| where type == 'microsoft.insights/actiongroups'
| extend enabled = properties.enabled
| extend emailReceivers = properties.emailReceivers
| extend smsReceivers = properties.smsReceivers
| extend webhookReceivers = properties.webhookReceivers
| extend armRoleReceivers = properties.armRoleReceivers
| extend logicAppReceivers = properties.logicAppReceivers
| project id, name, type, subscriptionId, resourceGroup, location, tags,
    enabled, emailReceivers, smsReceivers, webhookReceivers, 
    armRoleReceivers, logicAppReceivers
"@

    return Invoke-WAFQuery -Query $query -SubscriptionIds $SubscriptionIds
}

<#
.SYNOPSIS
    Retrieves Azure Monitor Workbooks.

.DESCRIPTION
    The Get-WAFAzureMonitorWorkbooks function queries Azure Resource Graph to retrieve
    all Azure Monitor workbooks for observability dashboards.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of Azure Monitor workbook configurations.

.EXAMPLE
    $workbooks = Get-WAFAzureMonitorWorkbooks -SubscriptionIds @('sub1', 'sub2')
#>
function Get-WAFAzureMonitorWorkbooks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $query = @"
Resources
| where type == 'microsoft.insights/workbooks'
| extend displayName = properties.displayName
| extend category = properties.category
| extend workbookType = properties.workbookType
| extend timeModified = properties.timeModified
| project id, name, type, subscriptionId, resourceGroup, location, tags,
    displayName, category, workbookType, timeModified
"@

    return Invoke-WAFQuery -Query $query -SubscriptionIds $SubscriptionIds
}

<#
.SYNOPSIS
    Retrieves Azure Managed Grafana workspaces.

.DESCRIPTION
    The Get-WAFGrafanaWorkspaces function queries Azure Resource Graph to retrieve
    all Azure Managed Grafana workspaces for observability dashboards.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of Grafana workspace configurations.

.EXAMPLE
    $grafana = Get-WAFGrafanaWorkspaces -SubscriptionIds @('sub1', 'sub2')
#>
function Get-WAFGrafanaWorkspaces {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $query = @"
Resources
| where type == 'microsoft.dashboard/grafana'
| extend endpoint = properties.properties.endpoint
| extend provisioningState = properties.properties.provisioningState
| extend grafanaVersion = properties.properties.grafanaVersion
| extend publicNetworkAccess = properties.properties.publicNetworkAccess
| extend apiKey = properties.properties.apiKey
| project id, name, type, subscriptionId, resourceGroup, location, tags,
    endpoint, provisioningState, grafanaVersion, publicNetworkAccess, apiKey
"@

    return Invoke-WAFQuery -Query $query -SubscriptionIds $SubscriptionIds
}

<#
.SYNOPSIS
    Tests diagnostic settings coverage for resources.

.DESCRIPTION
    Helper function to analyze which resources have diagnostic settings configured.

.PARAMETER Resources
    Array of Azure resources to analyze.

.PARAMETER DiagnosticSettings
    Array of diagnostic settings configurations.

.OUTPUTS
    Returns an array of MonitoringConfigurationObj objects for diagnostic settings.
#>
function Test-WAFDiagnosticCoverage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $Resources,

        [Parameter(Mandatory = $true)]
        [array] $DiagnosticSettings
    )

    $monitoringObjects = @()

    foreach ($resource in $Resources) {
        $resourceDiagnostics = $DiagnosticSettings | Where-Object { $_.targetResourceId -eq $resource.id }
        
        if ($resourceDiagnostics) {
            $config = @{
                DiagnosticSettingsCount = $resourceDiagnostics.Count
                LogCategories = ($resourceDiagnostics.logs | ForEach-Object { $_.category }) -join ', '
                MetricsEnabled = ($resourceDiagnostics.metrics | Where-Object { $_.enabled -eq $true }).Count -gt 0
                WorkspaceConfigured = ($resourceDiagnostics.workspaceId | Where-Object { $_ -ne $null }).Count -gt 0
                StorageConfigured = ($resourceDiagnostics.storageAccountId | Where-Object { $_ -ne $null }).Count -gt 0
                EventHubConfigured = ($resourceDiagnostics.eventHubAuthorizationRuleId | Where-Object { $_ -ne $null }).Count -gt 0
            }
            $status = 'Configured'
        } else {
            $config = @{
                DiagnosticSettingsCount = 0
                LogCategories = 'None'
                MetricsEnabled = $false
                WorkspaceConfigured = $false
                StorageConfigured = $false
                EventHubConfigured = $false
            }
            $status = 'Missing'
        }

        $monitoringObjects += [MonitoringConfigurationObj]::new($resource, 'DiagnosticSettings', $status, $config)
    }

    return $monitoringObjects
}

<#
.SYNOPSIS
    Tests Application Insights coverage for resources.

.DESCRIPTION
    Helper function to analyze which resources have Application Insights configured.

.PARAMETER Resources
    Array of Azure resources to analyze.

.PARAMETER ApplicationInsights
    Array of Application Insights configurations.

.OUTPUTS
    Returns an array of MonitoringConfigurationObj objects for Application Insights.
#>
function Test-WAFApplicationInsightsCoverage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $Resources,

        [Parameter(Mandatory = $true)]
        [array] $ApplicationInsights
    )

    $monitoringObjects = @()
    $webApps = $Resources | Where-Object { $_.type -in @('Microsoft.Web/sites', 'Microsoft.Web/functionapps') }

    foreach ($webApp in $webApps) {
        $resourceGroup = $webApp.resourceGroup
        $appInsights = $ApplicationInsights | Where-Object { $_.resourceGroup -eq $resourceGroup }
        
        if ($appInsights) {
            $config = @{
                ApplicationInsightsCount = $appInsights.Count
                WorkspaceIntegration = ($appInsights.workspaceId | Where-Object { $_ -ne $null }).Count -gt 0
                RetentionDays = ($appInsights.retentionInDays | Measure-Object -Average).Average
                SamplingPercentage = ($appInsights.samplingPercentage | Measure-Object -Average).Average
                PublicNetworkAccess = ($appInsights.publicNetworkAccess -contains 'Enabled')
            }
            $status = 'Configured'
        } else {
            $config = @{
                ApplicationInsightsCount = 0
                WorkspaceIntegration = $false
                RetentionDays = 0
                SamplingPercentage = 0
                PublicNetworkAccess = $false
            }
            $status = 'Missing'
        }

        $monitoringObjects += [MonitoringConfigurationObj]::new($webApp, 'ApplicationInsights', $status, $config)
    }

    return $monitoringObjects
}

<#
.SYNOPSIS
    Tests metric alert coverage for resources.

.DESCRIPTION
    Helper function to analyze which resources have metric alerts configured.

.PARAMETER Resources
    Array of Azure resources to analyze.

.PARAMETER MetricAlerts
    Array of metric alert configurations.

.OUTPUTS
    Returns an array of MonitoringConfigurationObj objects for metric alerts.
#>
function Test-WAFMetricAlertCoverage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $Resources,

        [Parameter(Mandatory = $true)]
        [array] $MetricAlerts
    )

    $monitoringObjects = @()

    foreach ($resource in $Resources) {
        $resourceAlerts = $MetricAlerts | Where-Object { 
            $_.scopes -contains $resource.id -or 
            $_.targetResourceType -eq $resource.type
        }
        
        if ($resourceAlerts) {
            $config = @{
                MetricAlertsCount = $resourceAlerts.Count
                EnabledAlerts = ($resourceAlerts | Where-Object { $_.enabled -eq $true }).Count
                CriticalAlerts = ($resourceAlerts | Where-Object { $_.severity -in @(0, 1) }).Count
                ActionsConfigured = ($resourceAlerts | Where-Object { $_.actions.Count -gt 0 }).Count
                EvaluationFrequency = ($resourceAlerts.evaluationFrequency | Group-Object | Sort-Object Count -Descending | Select-Object -First 1).Name
            }
            $status = 'Configured'
        } else {
            $config = @{
                MetricAlertsCount = 0
                EnabledAlerts = 0
                CriticalAlerts = 0
                ActionsConfigured = 0
                EvaluationFrequency = 'None'
            }
            $status = 'Missing'
        }

        $monitoringObjects += [MonitoringConfigurationObj]::new($resource, 'MetricAlerts', $status, $config)
    }

    return $monitoringObjects
}

<#
.SYNOPSIS
    Tests activity log alert coverage for subscriptions.

.DESCRIPTION
    Helper function to analyze activity log alert configurations.

.PARAMETER Resources
    Array of Azure resources to analyze.

.PARAMETER ActivityLogAlerts
    Array of activity log alert configurations.

.OUTPUTS
    Returns an array of MonitoringConfigurationObj objects for activity log alerts.
#>
function Test-WAFActivityLogAlertCoverage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $Resources,

        [Parameter(Mandatory = $true)]
        [array] $ActivityLogAlerts
    )

    $monitoringObjects = @()
    $subscriptions = $Resources | Group-Object subscriptionId

    foreach ($subscription in $subscriptions) {
        $subscriptionId = $subscription.Name
        $subAlerts = $ActivityLogAlerts | Where-Object { 
            $_.scopes -contains "/subscriptions/$subscriptionId" 
        }
        
        if ($subAlerts) {
            $config = @{
                ActivityLogAlertsCount = $subAlerts.Count
                EnabledAlerts = ($subAlerts | Where-Object { $_.enabled -eq $true }).Count
                ActionsConfigured = ($subAlerts | Where-Object { $_.actions.Count -gt 0 }).Count
                ServiceHealthAlerts = ($subAlerts | Where-Object { 
                    $_.condition.allOf | Where-Object { $_.field -eq 'category' -and $_.equals -eq 'ServiceHealth' }
                }).Count
                SecurityAlerts = ($subAlerts | Where-Object { 
                    $_.condition.allOf | Where-Object { $_.field -eq 'category' -and $_.equals -eq 'Security' }
                }).Count
            }
            $status = 'Configured'
        } else {
            $config = @{
                ActivityLogAlertsCount = 0
                EnabledAlerts = 0
                ActionsConfigured = 0
                ServiceHealthAlerts = 0
                SecurityAlerts = 0
            }
            $status = 'Missing'
        }

        # Create a subscription-level object for activity log alerts
        $subscriptionObj = @{
            id = "/subscriptions/$subscriptionId"
            name = $subscriptionId
            type = 'Microsoft.Subscription/Subscriptions'
            subscriptionId = $subscriptionId
            resourceGroup = 'N/A'
            location = 'global'
            tags = @{}
        }

        $monitoringObjects += [MonitoringConfigurationObj]::new($subscriptionObj, 'ActivityLogAlerts', $status, $config)
    }

    return $monitoringObjects
}

<#
.SYNOPSIS
    Builds monitoring objects for reporting.

.DESCRIPTION
    The Build-WAFMonitoringObject function creates standardized monitoring objects
    for integration with the WARA reporting system.

.PARAMETER MonitoringConfigurations
    Array of monitoring configuration objects.

.OUTPUTS
    Returns an array of standardized monitoring objects for reporting.

.EXAMPLE
    $monitoringObjects = Build-WAFMonitoringObject -MonitoringConfigurations $configs
#>
function Build-WAFMonitoringObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $MonitoringConfigurations
    )

    $standardizedObjects = @()

    foreach ($config in $MonitoringConfigurations) {
        $obj = [PSCustomObject]@{
            ResourceId = $config.ResourceId
            ResourceName = $config.ResourceName
            ResourceType = $config.ResourceType
            SubscriptionId = $config.SubscriptionId
            ResourceGroupName = $config.ResourceGroupName
            Location = $config.Location
            ConfigurationType = $config.ConfigurationType
            ConfigurationStatus = $config.ConfigurationStatus
            Configuration = $config.Configuration
            Recommendation = $config.Recommendation
            Impact = $config.Impact
            Description = $config.Description
            Tags = $config.Tags
            Category = 'Monitoring & Observability'
            ValidationAction = if ($config.ConfigurationStatus -eq 'Missing') { 
                "REQUIRED ACTION: Configure $($config.ConfigurationType) for improved observability" 
            } else { 
                "REVIEW: Validate $($config.ConfigurationType) configuration meets requirements" 
            }
        }
        $standardizedObjects += $obj
    }

    return $standardizedObjects
}

<#
.SYNOPSIS
    Tests overall monitoring coverage and provides recommendations.

.DESCRIPTION
    The Test-WAFMonitoringCoverage function analyzes the overall monitoring coverage
    across the environment and provides high-level recommendations.

.PARAMETER SubscriptionIds
    An array of subscription IDs to analyze.

.OUTPUTS
    Returns a summary object with monitoring coverage analysis.

.EXAMPLE
    $coverageAnalysis = Test-WAFMonitoringCoverage -SubscriptionIds @('sub1', 'sub2')
#>
function Test-WAFMonitoringCoverage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $analysis = [PSCustomObject]@{
        OverallCoverage = 'Unknown'
        DiagnosticSettingsCoverage = 0
        ApplicationInsightsCoverage = 0
        MetricAlertsCoverage = 0
        ActivityLogAlertsCoverage = 0
        Recommendations = [System.Collections.ArrayList]@()
        CriticalGaps = [System.Collections.ArrayList]@()
        Summary = ''
    }

    try {
        # Get monitoring configuration
        $monitoringConfig = Get-WAFMonitoringConfiguration -SubscriptionIds $SubscriptionIds

        # Calculate coverage percentages
        $totalResources = ($monitoringConfig | Group-Object ResourceId).Count
        if ($totalResources -gt 0) {
            $diagnosticsConfigured = ($monitoringConfig | Where-Object { $_.ConfigurationType -eq 'DiagnosticSettings' -and $_.ConfigurationStatus -eq 'Configured' }).Count
            $analysis.DiagnosticSettingsCoverage = [math]::Round(($diagnosticsConfigured / $totalResources) * 100, 2)

            $appInsightsConfigured = ($monitoringConfig | Where-Object { $_.ConfigurationType -eq 'ApplicationInsights' -and $_.ConfigurationStatus -eq 'Configured' }).Count
            $webAppsTotal = ($monitoringConfig | Where-Object { $_.ConfigurationType -eq 'ApplicationInsights' }).Count
            if ($webAppsTotal -gt 0) {
                $analysis.ApplicationInsightsCoverage = [math]::Round(($appInsightsConfigured / $webAppsTotal) * 100, 2)
            }

            $alertsConfigured = ($monitoringConfig | Where-Object { $_.ConfigurationType -eq 'MetricAlerts' -and $_.ConfigurationStatus -eq 'Configured' }).Count
            $analysis.MetricAlertsCoverage = [math]::Round(($alertsConfigured / $totalResources) * 100, 2)

            $activityAlertsConfigured = ($monitoringConfig | Where-Object { $_.ConfigurationType -eq 'ActivityLogAlerts' -and $_.ConfigurationStatus -eq 'Configured' }).Count
            $subscriptionsTotal = ($monitoringConfig | Where-Object { $_.ConfigurationType -eq 'ActivityLogAlerts' }).Count
            if ($subscriptionsTotal -gt 0) {
                $analysis.ActivityLogAlertsCoverage = [math]::Round(($activityAlertsConfigured / $subscriptionsTotal) * 100, 2)
            }
        }

        # Determine overall coverage
        $averageCoverage = ($analysis.DiagnosticSettingsCoverage + $analysis.ApplicationInsightsCoverage + $analysis.MetricAlertsCoverage + $analysis.ActivityLogAlertsCoverage) / 4
        $analysis.OverallCoverage = switch ($averageCoverage) {
            { $_ -ge 80 } { 'Excellent' }
            { $_ -ge 60 } { 'Good' }
            { $_ -ge 40 } { 'Fair' }
            { $_ -ge 20 } { 'Poor' }
            default { 'Critical' }
        }

        # Generate recommendations
        if ($analysis.DiagnosticSettingsCoverage -lt 80) {
            [void]$analysis.Recommendations.Add("Increase diagnostic settings coverage to at least 80% (currently $($analysis.DiagnosticSettingsCoverage)%)")
        }
        if ($analysis.ApplicationInsightsCoverage -lt 90) {
            [void]$analysis.Recommendations.Add("Ensure Application Insights is configured for all web applications (currently $($analysis.ApplicationInsightsCoverage)%)")
        }
        if ($analysis.MetricAlertsCoverage -lt 70) {
            [void]$analysis.Recommendations.Add("Implement metric alerts for critical resources (currently $($analysis.MetricAlertsCoverage)%)")
        }
        if ($analysis.ActivityLogAlertsCoverage -lt 100) {
            [void]$analysis.Recommendations.Add("Configure activity log alerts for all subscriptions (currently $($analysis.ActivityLogAlertsCoverage)%)")
        }

        # Identify critical gaps
        $criticalResources = $monitoringConfig | Where-Object { 
            $_.Impact -eq 'High' -and $_.ConfigurationStatus -eq 'Missing' 
        }
        foreach ($resource in $criticalResources) {
            [void]$analysis.CriticalGaps.Add("$($resource.ResourceName) - Missing $($resource.ConfigurationType)")
        }

        # Create summary
        $analysis.Summary = "Monitoring Coverage Analysis: $($analysis.OverallCoverage) overall coverage with $($totalResources) resources analyzed across $($SubscriptionIds.Count) subscription(s)."

    } catch {
        $analysis.Summary = "Error analyzing monitoring coverage: $($_.Exception.Message)"
        Write-Error "Failed to analyze monitoring coverage: $($_.Exception.Message)"
    }

    return $analysis
}
