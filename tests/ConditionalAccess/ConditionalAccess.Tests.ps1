BeforeAll {
    $ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$ModuleRoot/M365TenantSuperpowers.psd1" -Force -ErrorAction SilentlyContinue
}

Describe 'Conditional Access Module - Function Exports' {
    $expectedFunctions = @(
        'New-M365CAPolicy'
        'Get-M365CAPolicy'
        'Set-M365CAPolicy'
        'Remove-M365CAPolicy'
        'Test-M365CAPolicy'
        'Import-M365CAPolicySet'
        'Export-M365CAPolicySet'
    )

    foreach ($funcName in $expectedFunctions) {
        It "Should export $funcName" {
            $cmd = Get-Command $funcName -Module 'M365TenantSuperpowers' -ErrorAction SilentlyContinue
            $cmd | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Conditional Access Module - Parameter Validation' {
    It 'New-M365CAPolicy should support ShouldProcess' {
        $cmd = Get-Command 'New-M365CAPolicy'
        $cmd.Parameters.Keys | Should -Contain 'WhatIf'
        $cmd.Parameters.Keys | Should -Contain 'Confirm'
    }

    It 'Remove-M365CAPolicy should have High ConfirmImpact' {
        $cmd = Get-Command 'Remove-M365CAPolicy'
        $cmd.Parameters.Keys | Should -Contain 'Confirm'
    }

    It 'Import-M365CAPolicySet should have mandatory PolicyNames parameter' {
        $cmd = Get-Command 'Import-M365CAPolicySet'
        $param = $cmd.Parameters['PolicyNames']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Be $true
    }
}

Describe 'CA Policy Config Files' {
    $configPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'configs/ConditionalAccess'

    It 'Should have config files' {
        $configs = Get-ChildItem $configPath -Filter '*.json' -Exclude '_schema.json'
        $configs.Count | Should -BeGreaterOrEqual 10
    }

    $configs = Get-ChildItem $configPath -Filter '*.json' -Exclude '_schema.json'

    foreach ($config in $configs) {
        Context "Config: $($config.BaseName)" {
            BeforeAll {
                $configData = Get-Content $config.FullName -Raw | ConvertFrom-Json -AsHashtable
            }

            It 'Should be valid JSON with required sections' {
                $configData | Should -Not -BeNullOrEmpty
                $configData.Keys | Should -Contain 'metadata'
                $configData.Keys | Should -Contain 'policy'
            }

            It 'Should have required metadata fields' {
                $configData.metadata.Keys | Should -Contain 'id'
                $configData.metadata.Keys | Should -Contain 'name'
                $configData.metadata.Keys | Should -Contain 'description'
                $configData.metadata.Keys | Should -Contain 'severity'
                $configData.metadata.Keys | Should -Contain 'category'
            }

            It 'Should have a valid policy ID format (CANNN)' {
                $configData.metadata.id | Should -Match '^CA\d{3}$'
            }

            It 'Should have a displayName in the policy section' {
                $configData.policy.displayName | Should -Not -BeNullOrEmpty
            }

            It 'Should default to report-only state' {
                $configData.policy.state | Should -Be 'enabledForReportingButNotEnforced'
            }

            It 'Should have conditions defined' {
                $configData.policy.conditions | Should -Not -BeNullOrEmpty
            }

            It 'Should have a severity of Critical, High, Medium, or Low' {
                $configData.metadata.severity | Should -BeIn @('Critical', 'High', 'Medium', 'Low')
            }
        }
    }
}
