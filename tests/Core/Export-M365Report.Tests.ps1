BeforeAll {
    $ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$ModuleRoot/M365TenantSuperpowers.psd1" -Force -ErrorAction SilentlyContinue
}

Describe 'Export-M365Report' {
    It 'Should be exported from the module' {
        $cmd = Get-Command 'Export-M365Report' -Module 'M365TenantSuperpowers' -ErrorAction SilentlyContinue
        $cmd | Should -Not -BeNullOrEmpty
    }

    It 'Should accept pipeline input' {
        $cmd = Get-Command 'Export-M365Report'
        $param = $cmd.Parameters['InputData']
        $param.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipeline | Should -Be $true
    }

    It 'Should support Console, CSV, HTML, JSON formats' {
        $cmd = Get-Command 'Export-M365Report'
        $validateSet = $cmd.Parameters['Format'].Attributes.Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] })
        $validateSet.ValidValues | Should -Contain 'Console'
        $validateSet.ValidValues | Should -Contain 'CSV'
        $validateSet.ValidValues | Should -Contain 'HTML'
        $validateSet.ValidValues | Should -Contain 'JSON'
    }

    Context 'CSV Export' {
        It 'Should create a CSV file' {
            $testData = @(
                [PSCustomObject]@{ Name = 'Test1'; Value = 'A' }
                [PSCustomObject]@{ Name = 'Test2'; Value = 'B' }
            )
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "m365test_$(Get-Random)"
            try {
                $testData | Export-M365Report -Format CSV -OutputPath $tempDir -Title 'TestReport'
                $csvFiles = Get-ChildItem $tempDir -Filter '*.csv'
                $csvFiles | Should -Not -BeNullOrEmpty
                $content = Import-Csv $csvFiles[0].FullName
                $content.Count | Should -Be 2
            }
            finally {
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
            }
        }
    }

    Context 'JSON Export' {
        It 'Should create a valid JSON file' {
            $testData = @(
                [PSCustomObject]@{ Name = 'Test1'; Value = 'A' }
            )
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "m365test_$(Get-Random)"
            try {
                $testData | Export-M365Report -Format JSON -OutputPath $tempDir -Title 'TestReport'
                $jsonFiles = Get-ChildItem $tempDir -Filter '*.json'
                $jsonFiles | Should -Not -BeNullOrEmpty
                $content = Get-Content $jsonFiles[0].FullName -Raw | ConvertFrom-Json
                $content | Should -Not -BeNullOrEmpty
            }
            finally {
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
            }
        }
    }

    Context 'HTML Export' {
        It 'Should create an HTML file with proper structure' {
            $testData = @(
                [PSCustomObject]@{ Name = 'Test1'; Value = 'A' }
            )
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "m365test_$(Get-Random)"
            try {
                $testData | Export-M365Report -Format HTML -OutputPath $tempDir -Title 'TestReport'
                $htmlFiles = Get-ChildItem $tempDir -Filter '*.html'
                $htmlFiles | Should -Not -BeNullOrEmpty
                $content = Get-Content $htmlFiles[0].FullName -Raw
                $content | Should -Match '<html>'
                $content | Should -Match 'M365TenantSuperpowers'
            }
            finally {
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
            }
        }
    }

    Context 'PassThru' {
        It 'Should return data when PassThru is specified' {
            $testData = @(
                [PSCustomObject]@{ Name = 'Test1'; Value = 'A' }
            )
            $result = $testData | Export-M365Report -Format Console -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
        }
    }
}
