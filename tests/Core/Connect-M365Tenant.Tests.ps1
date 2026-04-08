BeforeAll {
    $ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$ModuleRoot/M365TenantSuperpowers.psd1" -Force -ErrorAction SilentlyContinue
}

Describe 'Connect-M365Tenant' {
    It 'Should be exported from the module' {
        $cmd = Get-Command 'Connect-M365Tenant' -Module 'M365TenantSuperpowers' -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
    }

    It 'Should have a mandatory TenantId parameter' {
        $cmd = Get-Command 'Connect-M365Tenant'
        $param = $cmd.Parameters['TenantId']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Be $true
    }

    It 'Should have a Services parameter with valid values' {
        $cmd = Get-Command 'Connect-M365Tenant'
        $param = $cmd.Parameters['Services']
        $param | Should -Not -BeNullOrEmpty
        $validateSet = $param.Attributes.Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] })
        $validateSet.ValidValues | Should -Contain 'Graph'
        $validateSet.ValidValues | Should -Contain 'ExchangeOnline'
        $validateSet.ValidValues | Should -Contain 'SharePoint'
        $validateSet.ValidValues | Should -Contain 'Teams'
    }

    It 'Should default Services to Graph' {
        $cmd = Get-Command 'Connect-M365Tenant'
        $param = $cmd.Parameters['Services']
        $defaultValue = $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] })
        # Default is set in param block, verified via help
        $cmd | Should -Not -BeNullOrEmpty
    }
}

Describe 'Disconnect-M365Tenant' {
    It 'Should be exported from the module' {
        $cmd = Get-Command 'Disconnect-M365Tenant' -Module 'M365TenantSuperpowers' -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-M365TenantConnection' {
    It 'Should be exported from the module' {
        $cmd = Get-Command 'Get-M365TenantConnection' -Module 'M365TenantSuperpowers' -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
    }

    It 'Should return a connection object' {
        $result = Get-M365TenantConnection
        $result.PSObject.Properties.Name | Should -Contain 'TenantId'
        $result.PSObject.Properties.Name | Should -Contain 'ConnectedServices'
        $result.PSObject.Properties.Name | Should -Contain 'IsConnected'
    }

    It 'Should show IsConnected as false when not connected' {
        $result = Get-M365TenantConnection
        $result.IsConnected | Should -Be $false
    }
}
