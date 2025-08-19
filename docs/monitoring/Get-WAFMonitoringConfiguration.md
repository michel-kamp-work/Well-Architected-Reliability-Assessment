# Get-WAFMonitoringConfiguration

## Synopsis

Retrieves comprehensive monitoring configuration for Azure resources.

## Description

The `Get-WAFMonitoringConfiguration` function queries multiple Azure monitoring services to provide a complete view of monitoring and observability configuration across resources. This function serves as the main entry point for monitoring assessment and orchestrates calls to other specialized monitoring functions.

## Syntax

```powershell
Get-WAFMonitoringConfiguration 
    -SubscriptionIds <String[]> 
    [-ResourceGroupNames <String[]>] 
    [-ResourceTypes <String[]>]
```

## Parameters

### -SubscriptionIds

An array of subscription IDs to scope the monitoring configuration query. This parameter is mandatory.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: None
Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceGroupNames

An optional array of resource group names to filter the monitoring analysis. When specified, only resources in these resource groups will be analyzed.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: None
Required: False
Position: Named
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceTypes

An optional array of specific resource types to analyze for monitoring configuration. When specified, only resources of these types will be included in the analysis.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: None
Required: False
Position: Named
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

## Outputs

### MonitoringConfigurationObj[]

Returns an array of `MonitoringConfigurationObj` objects representing monitoring configurations across the specified scope. Each object contains:

- **Resource Information**: ID, name, type, subscription, resource group, location
- **Configuration Type**: Diagnostic settings, Application Insights, metric alerts, etc.
- **Configuration Status**: Configured, missing, or needs review
- **Configuration Details**: Specific configuration data
- **Recommendations**: Suggested improvements
- **Impact Assessment**: High, medium, or low impact

## Examples

### Example 1: Basic Monitoring Assessment

```powershell
$subscriptions = @('/subscriptions/00000000-0000-0000-0000-000000000000')
$monitoringConfig = Get-WAFMonitoringConfiguration -SubscriptionIds $subscriptions

# Display summary of findings
$monitoringConfig | Group-Object ConfigurationType, ConfigurationStatus | 
    Select-Object Name, Count | Sort-Object Name
```

This example retrieves monitoring configuration for all resources in the specified subscription and displays a summary grouped by configuration type and status.

### Example 2: Filtered Analysis by Resource Group

```powershell
$subscriptions = @('/subscriptions/00000000-0000-0000-0000-000000000000')
$resourceGroups = @('rg-production-web', 'rg-production-data')

$monitoringConfig = Get-WAFMonitoringConfiguration -SubscriptionIds $subscriptions -ResourceGroupNames $resourceGroups

# Focus on high-impact missing configurations
$criticalIssues = $monitoringConfig | Where-Object { 
    $_.ConfigurationStatus -eq 'Missing' -and $_.Impact -eq 'High' 
}
```

This example analyzes monitoring configuration for specific resource groups and identifies critical missing configurations.

### Example 3: Resource Type-Specific Analysis

```powershell
$subscriptions = @('/subscriptions/00000000-0000-0000-0000-000000000000')
$webResourceTypes = @('Microsoft.Web/sites', 'Microsoft.Web/serverFarms')

$webAppMonitoring = Get-WAFMonitoringConfiguration -SubscriptionIds $subscriptions -ResourceTypes $webResourceTypes

# Check Application Insights coverage for web apps
$appInsightsGaps = $webAppMonitoring | Where-Object { 
    $_.ConfigurationType -eq 'ApplicationInsights' -and $_.ConfigurationStatus -eq 'Missing' 
}
```

This example focuses on monitoring configuration for web applications and identifies Application Insights coverage gaps.

### Example 4: Multi-Subscription Analysis

```powershell
$subscriptions = @(
    '/subscriptions/00000000-0000-0000-0000-000000000000',
    '/subscriptions/11111111-1111-1111-1111-111111111111'
)

$monitoringConfig = Get-WAFMonitoringConfiguration -SubscriptionIds $subscriptions

# Generate summary report by subscription
$subscriptionSummary = $monitoringConfig | Group-Object SubscriptionId | ForEach-Object {
    [PSCustomObject]@{
        Subscription = $_.Name
        TotalResources = ($_.Group | Group-Object ResourceId).Count
        ConfiguredResources = ($_.Group | Where-Object { $_.ConfigurationStatus -eq 'Configured' } | Group-Object ResourceId).Count
        MissingConfigurations = ($_.Group | Where-Object { $_.ConfigurationStatus -eq 'Missing' }).Count
        HighImpactGaps = ($_.Group | Where-Object { $_.ConfigurationStatus -eq 'Missing' -and $_.Impact -eq 'High' }).Count
    }
}
```

This example analyzes monitoring across multiple subscriptions and generates a summary report.

## Notes

- This function aggregates data from multiple specialized monitoring functions
- The analysis covers diagnostic settings, Application Insights, metric alerts, activity log alerts, and other monitoring components
- Results are standardized using the `MonitoringConfigurationObj` class for consistent reporting
- The function uses Azure Resource Graph for efficient querying across large environments
- Requires appropriate read permissions on the specified subscriptions and resources

## Related Functions

- `Get-WAFApplicationInsightsConfiguration` - Specific Application Insights analysis
- `Get-WAFDiagnosticSettings` - Diagnostic settings collection
- `Get-WAFMetricAlerts` - Metric alert configuration analysis
- `Get-WAFActivityLogAlerts` - Activity log alert assessment
- `Test-WAFMonitoringCoverage` - Overall coverage analysis
- `Build-WAFMonitoringObject` - Object standardization for reporting

## See Also

- [Test-WAFMonitoringCoverage](Test-WAFMonitoringCoverage.md)
- [Get-WAFApplicationInsightsConfiguration](Get-WAFApplicationInsightsConfiguration.md)
- [Get-WAFDiagnosticSettings](Get-WAFDiagnosticSettings.md)
