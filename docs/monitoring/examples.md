# Example Usage of the Monitoring & Observability Module

This file demonstrates how to use the new monitoring and observability collector module in the Well-Architected Reliability Assessment (WARA).

## Basic Usage

```powershell
# Import the WARA module
# Import-Module WARA
Import-Module .\src\modules\wara\wara.psd1

# Define your subscription(s)
#$subscriptions = @('/subscriptions/00000000-0000-0000-0000-000000000000')
$subscriptions = @('/subscriptions/bcef6094-098a-4602-ab07-75b8a63230b9')


# Get comprehensive monitoring configuration
$monitoringConfig = Get-WAFMonitoringConfiguration -SubscriptionIds $subscriptions

# Display summary of findings
$monitoringConfig | Group-Object ConfigurationType, ConfigurationStatus | 
    Select-Object Name, Count | Sort-Object Name
```

## Coverage Analysis

```powershell
# Perform monitoring coverage analysis
$coverageAnalysis = Test-WAFMonitoringCoverage -SubscriptionIds $subscriptions

# Display overall coverage
Write-Host "Overall Coverage: $($coverageAnalysis.OverallCoverage)"
Write-Host "Diagnostic Settings: $($coverageAnalysis.DiagnosticSettingsCoverage)%"
Write-Host "Application Insights: $($coverageAnalysis.ApplicationInsightsCoverage)%"
Write-Host "Metric Alerts: $($coverageAnalysis.MetricAlertsCoverage)%"
Write-Host "Activity Log Alerts: $($coverageAnalysis.ActivityLogAlertsCoverage)%"

# Show recommendations
if ($coverageAnalysis.Recommendations) {
    Write-Host "`nRecommendations:"
    $coverageAnalysis.Recommendations | ForEach-Object { Write-Host "- $_" }
}

# Show critical gaps
if ($coverageAnalysis.CriticalGaps) {
    Write-Host "`nCritical Gaps:"
    $coverageAnalysis.CriticalGaps | ForEach-Object { Write-Host "- $_" }
}
```

## Specific Component Analysis

```powershell
# Analyze specific monitoring components
$appInsights = Get-WAFApplicationInsightsConfiguration -SubscriptionIds $subscriptions
$logAnalytics = Get-WAFLogAnalyticsWorkspaces -SubscriptionIds $subscriptions
$diagnosticSettings = Get-WAFDiagnosticSettings -SubscriptionIds $subscriptions
$metricAlerts = Get-WAFMetricAlerts -SubscriptionIds $subscriptions
$activityAlerts = Get-WAFActivityLogAlerts -SubscriptionIds $subscriptions
$actionGroups = Get-WAFActionGroups -SubscriptionIds $subscriptions

# Display component summaries
Write-Host "Application Insights instances: $($appInsights.Count)"
Write-Host "Log Analytics workspaces: $($logAnalytics.Count)"
Write-Host "Diagnostic settings: $($diagnosticSettings.Count)"
Write-Host "Metric alerts: $($metricAlerts.Count)"
Write-Host "Activity log alerts: $($activityAlerts.Count)"
Write-Host "Action groups: $($actionGroups.Count)"
```

## Filtered Analysis

```powershell
# Analyze specific resource groups
$resourceGroups = @('rg-production-web', 'rg-production-data')
$filteredConfig = Get-WAFMonitoringConfiguration -SubscriptionIds $subscriptions -ResourceGroupNames $resourceGroups

# Analyze specific resource types
$webResourceTypes = @('Microsoft.Web/sites', 'Microsoft.Web/serverFarms')
$webAppMonitoring = Get-WAFMonitoringConfiguration -SubscriptionIds $subscriptions -ResourceTypes $webResourceTypes

# Find critical missing configurations
$criticalIssues = $filteredConfig | Where-Object { 
    $_.ConfigurationStatus -eq 'Missing' -and $_.Impact -eq 'High' 
}

Write-Host "Critical monitoring gaps found: $($criticalIssues.Count)"
```

## Integration with WARA Workflow

```powershell
# The monitoring module is designed to integrate with the standard WARA workflow
# It can be called as part of the overall assessment or independently

# Example of building standardized objects for reporting
$standardizedObjects = Build-WAFMonitoringObject -MonitoringConfigurations $monitoringConfig

# These objects follow the same pattern as other WARA modules and can be included
# in the overall assessment report
```

## Advanced Usage Examples

### Multi-Subscription Analysis
```powershell
$subscriptions = @(
    '/subscriptions/00000000-0000-0000-0000-000000000000',
    '/subscriptions/11111111-1111-1111-1111-111111111111'
)

$results = @()
foreach ($subscription in $subscriptions) {
    $analysis = Test-WAFMonitoringCoverage -SubscriptionIds @($subscription)
    $results += [PSCustomObject]@{
        Subscription = $subscription.Split('/')[-1]
        OverallCoverage = $analysis.OverallCoverage
        DiagnosticSettings = $analysis.DiagnosticSettingsCoverage
        ApplicationInsights = $analysis.ApplicationInsightsCoverage
        MetricAlerts = $analysis.MetricAlertsCoverage
        ActivityLogAlerts = $analysis.ActivityLogAlertsCoverage
        CriticalGaps = $analysis.CriticalGaps.Count
    }
}

$results | Format-Table -AutoSize
```

### Coverage Tracking Over Time
```powershell
$analysis = Test-WAFMonitoringCoverage -SubscriptionIds $subscriptions

# Create tracking record
$trackingRecord = [PSCustomObject]@{
    Date = Get-Date
    OverallCoverage = $analysis.OverallCoverage
    DiagnosticSettingsCoverage = $analysis.DiagnosticSettingsCoverage
    ApplicationInsightsCoverage = $analysis.ApplicationInsightsCoverage
    MetricAlertsCoverage = $analysis.MetricAlertsCoverage
    ActivityLogAlertsCoverage = $analysis.ActivityLogAlertsCoverage
    TotalRecommendations = $analysis.Recommendations.Count
    CriticalGaps = $analysis.CriticalGaps.Count
}

# Export to CSV for tracking
$trackingRecord | Export-Csv -Path "monitoring_coverage_tracking.csv" -Append -NoTypeInformation
```

### Resource-Specific Analysis
```powershell
# Focus on web applications and their monitoring
$webApps = $monitoringConfig | Where-Object { 
    $_.ResourceType -eq 'Microsoft.Web/sites' 
}

# Group by configuration status
$webAppSummary = $webApps | Group-Object ConfigurationStatus | ForEach-Object {
    [PSCustomObject]@{
        Status = $_.Name
        Count = $_.Count
        Resources = ($_.Group.ResourceName -join ', ')
    }
}

$webAppSummary | Format-Table -Wrap
```

## Expected Output Examples

### Coverage Analysis Output
```
Overall Coverage: Good
Diagnostic Settings: 75.5%
Application Insights: 90.0%
Metric Alerts: 65.2%
Activity Log Alerts: 100.0%

Recommendations:
- Increase diagnostic settings coverage to at least 80% (currently 75.5%)
- Implement metric alerts for critical resources (currently 65.2%)

Critical Gaps:
- webapp-prod-01 - Missing DiagnosticSettings
- storage-prod-01 - Missing MetricAlerts
```

### Component Summary Output
```
Application Insights instances: 5
Log Analytics workspaces: 2
Diagnostic settings: 45
Metric alerts: 38
Activity log alerts: 3
Action groups: 2
```

## Notes

- The monitoring module requires appropriate read permissions on the specified subscriptions
- All functions use Azure Resource Graph for efficient querying across large environments
- Results are standardized using the `MonitoringConfigurationObj` class for consistent reporting
- The module integrates seamlessly with the existing WARA workflow and reporting system
