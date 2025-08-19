# Test-WAFMonitoringCoverage

## Synopsis

Tests overall monitoring coverage and provides recommendations.

## Description

The `Test-WAFMonitoringCoverage` function analyzes the overall monitoring coverage across the specified Azure environment and provides high-level recommendations. This function serves as a comprehensive assessment tool that evaluates monitoring completeness and identifies critical gaps in observability.

## Syntax

```powershell
Test-WAFMonitoringCoverage -SubscriptionIds <String[]>
```

## Parameters

### -SubscriptionIds

An array of subscription IDs to analyze for monitoring coverage. This parameter is mandatory.

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

## Outputs

### PSCustomObject

Returns a comprehensive monitoring coverage analysis object with the following properties:

- **OverallCoverage**: String indicating overall coverage level (Excellent/Good/Fair/Poor/Critical)
- **DiagnosticSettingsCoverage**: Percentage of resources with diagnostic settings configured
- **ApplicationInsightsCoverage**: Percentage of web applications with Application Insights
- **MetricAlertsCoverage**: Percentage of resources with metric alerts configured
- **ActivityLogAlertsCoverage**: Percentage of subscriptions with activity log alerts
- **Recommendations**: Array of specific improvement recommendations
- **CriticalGaps**: Array of high-priority missing configurations
- **Summary**: Text summary of the analysis results

## Examples

### Example 1: Basic Coverage Analysis

```powershell
$subscriptions = @('/subscriptions/00000000-0000-0000-0000-000000000000')
$coverageAnalysis = Test-WAFMonitoringCoverage -SubscriptionIds $subscriptions

# Display overall coverage
Write-Host "Overall Coverage: $($coverageAnalysis.OverallCoverage)"
Write-Host "Diagnostic Settings: $($coverageAnalysis.DiagnosticSettingsCoverage)%"
Write-Host "Application Insights: $($coverageAnalysis.ApplicationInsightsCoverage)%"
Write-Host "Metric Alerts: $($coverageAnalysis.MetricAlertsCoverage)%"
Write-Host "Activity Log Alerts: $($coverageAnalysis.ActivityLogAlertsCoverage)%"
```

This example performs a basic coverage analysis and displays key metrics.

### Example 2: Detailed Recommendations Report

```powershell
$subscriptions = @('/subscriptions/00000000-0000-0000-0000-000000000000')
$analysis = Test-WAFMonitoringCoverage -SubscriptionIds $subscriptions

# Display recommendations
Write-Host "`nRecommendations:"
$analysis.Recommendations | ForEach-Object { Write-Host "- $_" }

# Display critical gaps
if ($analysis.CriticalGaps.Count -gt 0) {
    Write-Host "`nCritical Gaps:"
    $analysis.CriticalGaps | ForEach-Object { Write-Host "- $_" }
}

Write-Host "`nSummary: $($analysis.Summary)"
```

This example displays detailed recommendations and identifies critical gaps that need immediate attention.

### Example 3: Multi-Subscription Coverage Comparison

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

This example compares monitoring coverage across multiple subscriptions.

### Example 4: Coverage Tracking Over Time

```powershell
$subscriptions = @('/subscriptions/00000000-0000-0000-0000-000000000000')
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

This example demonstrates how to track monitoring coverage improvements over time.

## Coverage Levels

The function evaluates overall coverage using the following scale:

- **Excellent** (80-100%): Comprehensive monitoring coverage with minimal gaps
- **Good** (60-79%): Strong monitoring foundation with some improvements needed
- **Fair** (40-59%): Basic monitoring in place but significant gaps exist
- **Poor** (20-39%): Limited monitoring coverage with many critical gaps
- **Critical** (0-19%): Minimal monitoring coverage requiring immediate attention

## Analysis Components

### Diagnostic Settings Coverage
- Percentage of resources with diagnostic settings configured
- Analysis includes log categories, metrics, and destination configuration
- Identifies resources missing diagnostic settings

### Application Insights Coverage
- Percentage of web applications and functions with Application Insights
- Evaluates configuration completeness and workspace integration
- Focuses on application-specific monitoring needs

### Metric Alerts Coverage
- Percentage of resources with appropriate metric alerts
- Analyzes alert severity, frequency, and action group integration
- Identifies resources lacking proactive monitoring

### Activity Log Alerts Coverage
- Percentage of subscriptions with activity log alerts configured
- Evaluates service health and security alert coverage
- Assesses subscription-level operational monitoring

## Recommendations

The function generates specific recommendations based on coverage gaps:

- **Diagnostic Settings**: Guidance on enabling logging and metrics collection
- **Application Insights**: Recommendations for application monitoring setup
- **Metric Alerts**: Suggestions for proactive alerting implementation
- **Activity Log Alerts**: Guidance on operational event monitoring

## Critical Gaps Identification

High-priority gaps are identified based on:

- **Impact Level**: High-impact resources missing critical monitoring
- **Resource Types**: Critical resource types without appropriate monitoring
- **Security Monitoring**: Missing security-related alerts and logging
- **Compliance Requirements**: Gaps affecting compliance with monitoring standards

## Notes

- The function uses `Get-WAFMonitoringConfiguration` internally for comprehensive analysis
- Coverage percentages are calculated based on applicable resources for each monitoring type
- Critical gaps focus on high-impact resources and configurations
- The analysis provides actionable insights for improving monitoring coverage
- Results can be used for compliance reporting and monitoring maturity assessment

## Related Functions

- `Get-WAFMonitoringConfiguration` - Comprehensive monitoring configuration collection
- `Get-WAFApplicationInsightsConfiguration` - Application Insights specific analysis
- `Get-WAFDiagnosticSettings` - Diagnostic settings assessment
- `Get-WAFMetricAlerts` - Metric alert configuration analysis
- `Build-WAFMonitoringObject` - Standardized monitoring object creation

## See Also

- [Get-WAFMonitoringConfiguration](Get-WAFMonitoringConfiguration.md)
- [Get-WAFApplicationInsightsConfiguration](Get-WAFApplicationInsightsConfiguration.md)
- [Get-WAFDiagnosticSettings](Get-WAFDiagnosticSettings.md)
