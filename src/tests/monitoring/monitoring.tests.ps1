using module ../../modules/wara/monitoring/monitoring.psd1

BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/monitoring/monitoring.psd1"
    Import-Module -Name $modulePath -Force
    
    # Mock test data for monitoring resources
    $test_ApplicationInsights = @(
        [PSCustomObject]@{
            id = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/microsoft.insights/components/appinsights-test'
            name = 'appinsights-test'
            type = 'microsoft.insights/components'
            subscriptionId = '00000000-0000-0000-0000-000000000000'
            resourceGroup = 'rg-test'
            location = 'eastus'
            tags = @{}
            appType = 'web'
            workspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/workspace-test'
            retentionInDays = 90
            samplingPercentage = 100
            publicNetworkAccess = 'Enabled'
            publicNetworkAccessForQuery = 'Enabled'
        }
    )
    
    $test_LogAnalyticsWorkspaces = @(
        [PSCustomObject]@{
            id = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/workspace-test'
            name = 'workspace-test'
            type = 'microsoft.operationalinsights/workspaces'
            subscriptionId = '00000000-0000-0000-0000-000000000000'
            resourceGroup = 'rg-test'
            location = 'eastus'
            tags = @{}
            retentionInDays = 30
            dailyQuotaGb = 5
            publicNetworkAccessForIngestion = 'Enabled'
            publicNetworkAccessForQuery = 'Enabled'
            sku = 'PerGB2018'
        }
    )
    
    $test_DiagnosticSettings = @(
        [PSCustomObject]@{
            id = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/microsoft.insights/diagnosticsettings/diag-test'
            name = 'diag-test'
            targetResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Web/sites/webapp-test'
            workspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/workspace-test'
            storageAccountId = $null
            eventHubAuthorizationRuleId = $null
            logs = @(
                [PSCustomObject]@{ category = 'AppServiceHTTPLogs'; enabled = $true }
                [PSCustomObject]@{ category = 'AppServiceConsoleLogs'; enabled = $true }
            )
            metrics = @(
                [PSCustomObject]@{ category = 'AllMetrics'; enabled = $true }
            )
            subscriptionId = '00000000-0000-0000-0000-000000000000'
            resourceGroup = 'rg-test'
        }
    )
    
    $test_MetricAlerts = @(
        [PSCustomObject]@{
            id = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/microsoft.insights/metricalerts/alert-cpu'
            name = 'alert-cpu'
            type = 'microsoft.insights/metricalerts'
            subscriptionId = '00000000-0000-0000-0000-000000000000'
            resourceGroup = 'rg-test'
            location = 'global'
            tags = @{}
            enabled = $true
            severity = 2
            evaluationFrequency = 'PT1M'
            windowSize = 'PT5M'
            targetResourceType = 'Microsoft.Web/sites'
            scopes = @('/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Web/sites/webapp-test')
            actions = @(
                [PSCustomObject]@{ actionGroupId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/microsoft.insights/actiongroups/ag-test' }
            )
            criteria = [PSCustomObject]@{ 'odata.type' = 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria' }
        }
    )
    
    $test_ActivityLogAlerts = @(
        [PSCustomObject]@{
            id = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/microsoft.insights/activitylogalerts/alert-servicehealth'
            name = 'alert-servicehealth'
            type = 'microsoft.insights/activitylogalerts'
            subscriptionId = '00000000-0000-0000-0000-000000000000'
            resourceGroup = 'rg-test'
            location = 'global'
            tags = @{}
            enabled = $true
            scopes = @('/subscriptions/00000000-0000-0000-0000-000000000000')
            condition = [PSCustomObject]@{
                allOf = @(
                    [PSCustomObject]@{ field = 'category'; equals = 'ServiceHealth' }
                )
            }
            actions = [PSCustomObject]@{
                actionGroups = @(
                    [PSCustomObject]@{ actionGroupId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/microsoft.insights/actiongroups/ag-test' }
                )
            }
        }
    )
    
    $test_ActionGroups = @(
        [PSCustomObject]@{
            id = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/microsoft.insights/actiongroups/ag-test'
            name = 'ag-test'
            type = 'microsoft.insights/actiongroups'
            subscriptionId = '00000000-0000-0000-0000-000000000000'
            resourceGroup = 'rg-test'
            location = 'global'
            tags = @{}
            enabled = $true
            emailReceivers = @(
                [PSCustomObject]@{ name = 'admin'; emailAddress = 'admin@contoso.com'; useCommonAlertSchema = $true }
            )
            smsReceivers = @()
            webhookReceivers = @()
            armRoleReceivers = @()
            logicAppReceivers = @()
        }
    )
    
    $test_Resources = @(
        [PSCustomObject]@{
            id = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Web/sites/webapp-test'
            name = 'webapp-test'
            type = 'Microsoft.Web/sites'
            subscriptionId = '00000000-0000-0000-0000-000000000000'
            resourceGroup = 'rg-test'
            location = 'eastus'
            tags = @{}
        }
        [PSCustomObject]@{
            id = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/storage-test'
            name = 'storage-test'
            type = 'Microsoft.Storage/storageAccounts'
            subscriptionId = '00000000-0000-0000-0000-000000000000'
            resourceGroup = 'rg-test'
            location = 'eastus'
            tags = @{}
        }
    )
    
    # Mock the utility functions
    Mock Invoke-WAFQuery -ModuleName monitoring -MockWith {
        param($Query, $SubscriptionIds)
        switch -Wildcard ($Query) {
            "*microsoft.insights/components*" { return $test_ApplicationInsights }
            "*microsoft.operationalinsights/workspaces*" { return $test_LogAnalyticsWorkspaces }
            "*microsoft.insights/diagnosticsettings*" { return $test_DiagnosticSettings }
            "*microsoft.insights/metricalerts*" { return $test_MetricAlerts }
            "*microsoft.insights/activitylogalerts*" { return $test_ActivityLogAlerts }
            "*microsoft.insights/actiongroups*" { return $test_ActionGroups }
            "*Resources*project id*" { return $test_Resources }
            default { return @() }
        }
    }
}

Describe 'Get-WAFApplicationInsightsConfiguration' {
    Context 'When given valid subscription IDs' {
        It 'Should return Application Insights configurations' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000')
            $result = Get-WAFApplicationInsightsConfiguration -SubscriptionIds $SubscriptionIds
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].name | Should -Be 'appinsights-test'
            $result[0].type | Should -Be 'microsoft.insights/components'
            $result[0].appType | Should -Be 'web'
            $result[0].retentionInDays | Should -Be 90
        }
    }
}

Describe 'Get-WAFLogAnalyticsWorkspaces' {
    Context 'When given valid subscription IDs' {
        It 'Should return Log Analytics workspace configurations' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000')
            $result = Get-WAFLogAnalyticsWorkspaces -SubscriptionIds $SubscriptionIds
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].name | Should -Be 'workspace-test'
            $result[0].type | Should -Be 'microsoft.operationalinsights/workspaces'
            $result[0].retentionInDays | Should -Be 30
            $result[0].sku | Should -Be 'PerGB2018'
        }
    }
}

Describe 'Get-WAFDiagnosticSettings' {
    Context 'When given valid subscription IDs' {
        It 'Should return diagnostic settings configurations' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000')
            $result = Get-WAFDiagnosticSettings -SubscriptionIds $SubscriptionIds
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].name | Should -Be 'diag-test'
            $result[0].targetResourceId | Should -Match 'webapp-test'
            $result[0].logs.Count | Should -Be 2
            $result[0].metrics.Count | Should -Be 1
        }
    }
}

Describe 'Get-WAFMetricAlerts' {
    Context 'When given valid subscription IDs' {
        It 'Should return metric alert configurations' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000')
            $result = Get-WAFMetricAlerts -SubscriptionIds $SubscriptionIds
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].name | Should -Be 'alert-cpu'
            $result[0].type | Should -Be 'microsoft.insights/metricalerts'
            $result[0].enabled | Should -Be $true
            $result[0].severity | Should -Be 2
            $result[0].targetResourceType | Should -Be 'Microsoft.Web/sites'
        }
    }
}

Describe 'Get-WAFActivityLogAlerts' {
    Context 'When given valid subscription IDs' {
        It 'Should return activity log alert configurations' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000')
            $result = Get-WAFActivityLogAlerts -SubscriptionIds $SubscriptionIds
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].name | Should -Be 'alert-servicehealth'
            $result[0].type | Should -Be 'microsoft.insights/activitylogalerts'
            $result[0].enabled | Should -Be $true
            $result[0].scopes | Should -Contain '/subscriptions/00000000-0000-0000-0000-000000000000'
        }
    }
}

Describe 'Get-WAFActionGroups' {
    Context 'When given valid subscription IDs' {
        It 'Should return action group configurations' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000')
            $result = Get-WAFActionGroups -SubscriptionIds $SubscriptionIds
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].name | Should -Be 'ag-test'
            $result[0].type | Should -Be 'microsoft.insights/actiongroups'
            $result[0].enabled | Should -Be $true
            $result[0].emailReceivers.Count | Should -Be 1
        }
    }
}

Describe 'Test-WAFDiagnosticCoverage' {
    Context 'When analyzing diagnostic settings coverage' {
        It 'Should return monitoring configuration objects for diagnostic settings' {
            $result = Test-WAFDiagnosticCoverage -Resources $test_Resources -DiagnosticSettings $test_DiagnosticSettings
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            
            # Web app should have diagnostic settings configured
            $webAppResult = $result | Where-Object { $_.ResourceName -eq 'webapp-test' }
            $webAppResult.ConfigurationType | Should -Be 'DiagnosticSettings'
            $webAppResult.ConfigurationStatus | Should -Be 'Configured'
            $webAppResult.Configuration.DiagnosticSettingsCount | Should -Be 1
            
            # Storage account should be missing diagnostic settings
            $storageResult = $result | Where-Object { $_.ResourceName -eq 'storage-test' }
            $storageResult.ConfigurationType | Should -Be 'DiagnosticSettings'
            $storageResult.ConfigurationStatus | Should -Be 'Missing'
            $storageResult.Configuration.DiagnosticSettingsCount | Should -Be 0
        }
    }
}

Describe 'Test-WAFApplicationInsightsCoverage' {
    Context 'When analyzing Application Insights coverage' {
        It 'Should return monitoring configuration objects for Application Insights' {
            $webApps = $test_Resources | Where-Object { $_.type -eq 'Microsoft.Web/sites' }
            $result = Test-WAFApplicationInsightsCoverage -Resources $webApps -ApplicationInsights $test_ApplicationInsights
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].ConfigurationType | Should -Be 'ApplicationInsights'
            $result[0].ConfigurationStatus | Should -Be 'Configured'
            $result[0].Configuration.ApplicationInsightsCount | Should -Be 1
            $result[0].Configuration.WorkspaceIntegration | Should -Be $true
        }
    }
}

Describe 'Test-WAFMetricAlertCoverage' {
    Context 'When analyzing metric alert coverage' {
        It 'Should return monitoring configuration objects for metric alerts' {
            $result = Test-WAFMetricAlertCoverage -Resources $test_Resources -MetricAlerts $test_MetricAlerts
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            
            # Web app should have metric alerts configured
            $webAppResult = $result | Where-Object { $_.ResourceName -eq 'webapp-test' }
            $webAppResult.ConfigurationType | Should -Be 'MetricAlerts'
            $webAppResult.ConfigurationStatus | Should -Be 'Configured'
            $webAppResult.Configuration.MetricAlertsCount | Should -Be 1
            
            # Storage account should be missing metric alerts
            $storageResult = $result | Where-Object { $_.ResourceName -eq 'storage-test' }
            $storageResult.ConfigurationType | Should -Be 'MetricAlerts'
            $storageResult.ConfigurationStatus | Should -Be 'Missing'
            $storageResult.Configuration.MetricAlertsCount | Should -Be 0
        }
    }
}

Describe 'Test-WAFActivityLogAlertCoverage' {
    Context 'When analyzing activity log alert coverage' {
        It 'Should return monitoring configuration objects for activity log alerts' {
            $result = Test-WAFActivityLogAlertCoverage -Resources $test_Resources -ActivityLogAlerts $test_ActivityLogAlerts
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].ConfigurationType | Should -Be 'ActivityLogAlerts'
            $result[0].ConfigurationStatus | Should -Be 'Configured'
            $result[0].Configuration.ActivityLogAlertsCount | Should -Be 1
            $result[0].Configuration.ServiceHealthAlerts | Should -Be 1
        }
    }
}

Describe 'MonitoringConfigurationObj' {
    Context 'When creating a monitoring configuration object' {
        It 'Should create a valid object with all properties' {
            $resource = $test_Resources[0]
            $config = [PSCustomObject]@{ TestProperty = 'TestValue' }
            $obj = [MonitoringConfigurationObj]::new($resource, 'DiagnosticSettings', 'Missing', $config)
            
            $obj.ResourceId | Should -Be $resource.id
            $obj.ResourceName | Should -Be $resource.name
            $obj.ResourceType | Should -Be $resource.type
            $obj.SubscriptionId | Should -Be $resource.subscriptionId
            $obj.ResourceGroupName | Should -Be $resource.resourceGroup
            $obj.Location | Should -Be $resource.location
            $obj.ConfigurationType | Should -Be 'DiagnosticSettings'
            $obj.ConfigurationStatus | Should -Be 'Missing'
            $obj.Configuration | Should -Be $config
            $obj.Recommendation | Should -Not -BeNullOrEmpty
            $obj.Impact | Should -Not -BeNullOrEmpty
            $obj.Description | Should -Not -BeNullOrEmpty
        }
        
        It 'Should set appropriate recommendations based on configuration type and status' {
            $resource = $test_Resources[0]
            $config = [PSCustomObject]@{}
            
            # Test missing diagnostic settings
            $obj1 = [MonitoringConfigurationObj]::new($resource, 'DiagnosticSettings', 'Missing', $config)
            $obj1.Impact | Should -Be 'High'
            $obj1.Recommendation | Should -Match 'Enable diagnostic settings'
            
            # Test configured Application Insights
            $obj2 = [MonitoringConfigurationObj]::new($resource, 'ApplicationInsights', 'Configured', $config)
            $obj2.Impact | Should -Be 'Low'
            $obj2.Recommendation | Should -Match 'Review Application Insights'
        }
    }
}

Describe 'Build-WAFMonitoringObject' {
    Context 'When building standardized monitoring objects' {
        It 'Should return standardized objects for reporting' {
            $resource = $test_Resources[0]
            $config = [PSCustomObject]@{ TestProperty = 'TestValue' }
            $monitoringConfig = @([MonitoringConfigurationObj]::new($resource, 'DiagnosticSettings', 'Missing', $config))
            
            $result = Build-WAFMonitoringObject -MonitoringConfigurations $monitoringConfig
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].ResourceId | Should -Be $resource.id
            $result[0].Category | Should -Be 'Monitoring & Observability'
            $result[0].ValidationAction | Should -Match 'REQUIRED ACTION'
        }
    }
}

Describe 'Get-WAFMonitoringConfiguration' {
    Context 'When getting comprehensive monitoring configuration' {
        It 'Should return monitoring configuration objects' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000')
            $result = Get-WAFMonitoringConfiguration -SubscriptionIds $SubscriptionIds
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            
            # Should include different configuration types
            $configTypes = $result | Group-Object ConfigurationType | Select-Object -ExpandProperty Name
            $configTypes | Should -Contain 'DiagnosticSettings'
            $configTypes | Should -Contain 'ApplicationInsights'
            $configTypes | Should -Contain 'MetricAlerts'
            $configTypes | Should -Contain 'ActivityLogAlerts'
        }
    }
}

Describe 'Test-WAFMonitoringCoverage' {
    Context 'When testing overall monitoring coverage' {
        It 'Should return a comprehensive coverage analysis' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000')
            $result = Test-WAFMonitoringCoverage -SubscriptionIds $SubscriptionIds
            
            $result | Should -Not -BeNullOrEmpty
            $result.OverallCoverage | Should -Not -BeNullOrEmpty
            $result.DiagnosticSettingsCoverage | Should -BeOfType [System.ValueType]
            $result.ApplicationInsightsCoverage | Should -BeOfType [System.ValueType]
            $result.MetricAlertsCoverage | Should -BeOfType [System.ValueType]
            $result.ActivityLogAlertsCoverage | Should -BeOfType [System.ValueType]
            $result.Recommendations | Should -Not -BeNullOrEmpty
            $result.CriticalGaps | Should -Not -BeNullOrEmpty
            $result.Summary | Should -Not -BeNullOrEmpty
        }
        
        It 'Should provide appropriate coverage levels' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000')
            $result = Test-WAFMonitoringCoverage -SubscriptionIds $SubscriptionIds
            
            $validCoverageValues = @('Excellent', 'Good', 'Fair', 'Poor', 'Critical')
            $result.OverallCoverage | Should -BeIn $validCoverageValues
        }
    }
}
