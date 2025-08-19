# Monitoring & Observability Module

The monitoring module provides comprehensive Azure monitoring and observability assessment capabilities for the Well-Architected Reliability Assessment (WARA). This module analyzes monitoring configurations across Azure resources to identify gaps and recommend improvements for better observability and reliability.

## Overview

This module follows the same patterns as other WARA modules, collecting and analyzing Azure monitoring configurations including:

- **Azure Monitor Components**: Application Insights, Log Analytics workspaces, diagnostic settings
- **Alerting Systems**: Metric alerts, activity log alerts, action groups
- **Observability Tools**: Azure Monitor workbooks, Azure Managed Grafana
- **Coverage Analysis**: Monitoring gaps, configuration issues, recommendations

## Key Functions

### Primary Collection Functions

- `Get-WAFMonitoringConfiguration` - Main function that orchestrates comprehensive monitoring analysis
- `Get-WAFApplicationInsightsConfiguration` - Collects Application Insights configurations
- `Get-WAFLogAnalyticsWorkspaces` - Retrieves Log Analytics workspace settings
- `Get-WAFDiagnosticSettings` - Analyzes diagnostic settings across resources
- `Get-WAFMetricAlerts` - Collects metric alert configurations
- `Get-WAFActivityLogAlerts` - Retrieves activity log alert settings
- `Get-WAFActionGroups` - Analyzes notification action groups
- `Get-WAFAzureMonitorWorkbooks` - Collects Azure Monitor workbooks
- `Get-WAFGrafanaWorkspaces` - Retrieves Azure Managed Grafana configurations

### Analysis Functions

- `Test-WAFMonitoringCoverage` - Provides overall monitoring coverage analysis
- `Build-WAFMonitoringObject` - Creates standardized monitoring objects for reporting

### Helper Functions

- `Test-WAFDiagnosticCoverage` - Analyzes diagnostic settings coverage
- `Test-WAFApplicationInsightsCoverage` - Checks Application Insights coverage for web apps
- `Test-WAFMetricAlertCoverage` - Evaluates metric alert coverage
- `Test-WAFActivityLogAlertCoverage` - Assesses activity log alert configuration

## Usage Examples

### Basic Monitoring Assessment

```powershell
# Get comprehensive monitoring configuration
$subscriptions = @('/subscriptions/00000000-0000-0000-0000-000000000000')
$monitoringConfig = Get-WAFMonitoringConfiguration -SubscriptionIds $subscriptions

# Analyze coverage
$coverageAnalysis = Test-WAFMonitoringCoverage -SubscriptionIds $subscriptions
```

### Specific Component Analysis

```powershell
# Analyze Application Insights
$appInsights = Get-WAFApplicationInsightsConfiguration -SubscriptionIds $subscriptions

# Check diagnostic settings
$diagnosticSettings = Get-WAFDiagnosticSettings -SubscriptionIds $subscriptions

# Review metric alerts
$metricAlerts = Get-WAFMetricAlerts -SubscriptionIds $subscriptions
```

### Integration with WARA Workflow

The monitoring module integrates with the main WARA collector to provide monitoring and observability assessments as part of the overall reliability analysis.

## Output Objects

### MonitoringConfigurationObj Class

The module uses a PowerShell class `MonitoringConfigurationObj` that includes:

- **Resource Information**: ID, name, type, subscription, resource group, location
- **Configuration Details**: Type, status, specific configuration data
- **Assessment Results**: Recommendations, impact level, descriptions
- **Metadata**: Tags and other resource attributes

### Coverage Analysis Object

The coverage analysis provides:

- **Overall Coverage Score**: Excellent/Good/Fair/Poor/Critical
- **Component Coverage Percentages**: Diagnostic settings, Application Insights, alerts
- **Recommendations**: Specific actions to improve monitoring
- **Critical Gaps**: High-priority missing configurations

## Configuration Types Analyzed

1. **Diagnostic Settings**
   - Log categories enabled
   - Metrics collection
   - Destination configuration (Log Analytics, Storage, Event Hub)

2. **Application Insights**
   - Application type and configuration
   - Workspace integration
   - Retention and sampling settings
   - Network access configuration

3. **Metric Alerts**
   - Alert rules and criteria
   - Severity and evaluation frequency
   - Action group integration
   - Resource coverage

4. **Activity Log Alerts**
   - Subscription-level monitoring
   - Service health and security alerts
   - Notification configuration

5. **Action Groups**
   - Notification channels (email, SMS, webhook)
   - Integration with alerts
   - Role-based notifications

6. **Observability Dashboards**
   - Azure Monitor workbooks
   - Azure Managed Grafana instances
   - Custom dashboard configurations

## Best Practices Enforced

- **Comprehensive Logging**: Ensures diagnostic settings are configured for all supported resources
- **Application Monitoring**: Validates Application Insights for web applications and functions
- **Proactive Alerting**: Checks for appropriate metric and activity log alerts
- **Notification Configuration**: Verifies action groups are properly configured
- **Retention Policies**: Reviews log and metric retention settings
- **Security Configuration**: Analyzes network access and authentication settings

## Integration Points

The monitoring module is designed to work seamlessly with:

- **WARA Collector**: Integrated into the main collection workflow
- **WARA Analyzer**: Provides data for reliability analysis
- **WARA Reports**: Contributes to overall assessment reports
- **Azure Resource Graph**: Uses ARG queries for efficient data collection
- **Utils Module**: Leverages shared utility functions

## Error Handling

The module includes comprehensive error handling:

- **Query Failures**: Graceful handling of Azure Resource Graph query issues
- **Missing Permissions**: Clear error messages for insufficient access rights
- **Resource Access**: Proper handling of resources that can't be accessed
- **Data Validation**: Validation of returned data structures

## Performance Considerations

- **Efficient Queries**: Uses Azure Resource Graph for fast, large-scale data collection
- **Parallel Processing**: Where possible, processes multiple subscriptions in parallel
- **Memory Management**: Handles large datasets efficiently
- **Pagination**: Properly handles large result sets

## Security Considerations

- **Least Privilege**: Requires only read permissions for assessment
- **Data Privacy**: Doesn't collect sensitive configuration data
- **Network Security**: Analyzes network access configurations for security compliance
- **Authentication**: Uses existing Azure authentication context

## Future Enhancements

Potential areas for expansion:

- **Custom Metrics**: Analysis of custom metric definitions
- **Log Analytics Queries**: Validation of saved queries and workbooks
- **Cost Analysis**: Monitoring cost optimization recommendations
- **Performance Baselines**: Historical performance trend analysis
- **Compliance Checks**: Industry-specific monitoring compliance validation
