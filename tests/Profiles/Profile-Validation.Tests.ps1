BeforeAll {
    $ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$ModuleRoot/M365TenantSuperpowers.psd1" -Force -ErrorAction SilentlyContinue
}

Describe 'Profile Validation' {
    $profilePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'profiles'
    $profiles = Get-ChildItem $profilePath -Filter '*.json' -Exclude '_schema.json'

    It 'Should have at least one profile' {
        $profiles.Count | Should -BeGreaterOrEqual 1
    }

    foreach ($profile in $profiles) {
        Context "Profile: $($profile.BaseName)" {
            BeforeAll {
                $profileData = Get-Content $profile.FullName -Raw | ConvertFrom-Json -AsHashtable
            }

            It 'Should be valid JSON with required sections' {
                $profileData | Should -Not -BeNullOrEmpty
                $profileData.Keys | Should -Contain 'metadata'
                $profileData.Keys | Should -Contain 'requiredServices'
                $profileData.Keys | Should -Contain 'steps'
            }

            It 'Should have metadata with name, description, and version' {
                $profileData.metadata.name | Should -Not -BeNullOrEmpty
                $profileData.metadata.description | Should -Not -BeNullOrEmpty
                $profileData.metadata.version | Should -Match '^\d+\.\d+\.\d+$'
            }

            It 'Should have valid required services' {
                $validServices = @('Graph', 'ExchangeOnline', 'SharePoint', 'Teams')
                foreach ($service in $profileData.requiredServices) {
                    $service | Should -BeIn $validServices
                }
            }

            It 'Should have steps with required fields' {
                foreach ($step in $profileData.steps) {
                    $step.Keys | Should -Contain 'order'
                    $step.Keys | Should -Contain 'module'
                    $step.Keys | Should -Contain 'action'
                    $step.Keys | Should -Contain 'description'
                }
            }

            It 'Should have unique step order numbers' {
                $orders = $profileData.steps | ForEach-Object { $_.order }
                $uniqueOrders = $orders | Select-Object -Unique
                $orders.Count | Should -Be $uniqueOrders.Count
            }

            It 'Should reference existing config files in steps' {
                $configRoot = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'configs'
                foreach ($step in $profileData.steps) {
                    if ($step.configs) {
                        foreach ($configName in $step.configs) {
                            $configFile = Join-Path $configRoot "$($step.module)/$configName.json"
                            Test-Path $configFile | Should -Be $true -Because "Config '$configName' referenced in step $($step.order) should exist"
                        }
                    }
                }
            }

            It 'Should reference valid module action functions' {
                foreach ($step in $profileData.steps) {
                    $cmd = Get-Command $step.action -ErrorAction SilentlyContinue
                    $cmd | Should -Not -BeNullOrEmpty -Because "Action '$($step.action)' in step $($step.order) should be a valid command"
                }
            }
        }
    }
}

Describe 'Invoke-M365Profile' {
    It 'Should be exported from the module' {
        $cmd = Get-Command 'Invoke-M365Profile' -Module 'M365TenantSuperpowers' -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
    }

    It 'Should support ShouldProcess (WhatIf)' {
        $cmd = Get-Command 'Invoke-M365Profile'
        $cmd.Parameters.Keys | Should -Contain 'WhatIf'
    }

    It 'Should have mandatory Name parameter' {
        $cmd = Get-Command 'Invoke-M365Profile'
        $param = $cmd.Parameters['Name']
        $param | Should -Not -BeNullOrEmpty
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Be $true
    }

    It 'Should error on non-existent profile' {
        { Invoke-M365Profile -Name 'NonExistentProfile-12345' -ErrorAction Stop } | Should -Throw
    }
}
