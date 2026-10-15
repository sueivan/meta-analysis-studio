$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$found = @()
$cmd = Get-Command Rscript.exe -ErrorAction SilentlyContinue
if ($cmd) { $found += $cmd.Source }
foreach ($root in @("$env:ProgramFiles\R", "${env:ProgramFiles(x86)}\R", "$env:LOCALAPPDATA\Programs\R", 'C:\R')) {
 if ($root -and (Test-Path $root)) { $found += @(Get-ChildItem -Path $root -Filter Rscript.exe -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName) }
}
foreach ($key in @('HKLM:\SOFTWARE\R-core\R','HKCU:\SOFTWARE\R-core\R','HKLM:\SOFTWARE\WOW6432Node\R-core\R')) {
 if (Test-Path $key) { $install=(Get-ItemProperty $key -ErrorAction SilentlyContinue).'InstallPath'; if ($install) { $found += @(Join-Path $install 'bin\Rscript.exe') } }
}
$r = $found | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $r) {
 Write-Host 'Rscript.exe not found. Select Rscript.exe in the file dialog.'
 Add-Type -AssemblyName System.Windows.Forms
 $dialog=New-Object System.Windows.Forms.OpenFileDialog
 $dialog.Filter='Rscript.exe|Rscript.exe'
 if ($dialog.ShowDialog() -ne 'OK') { exit 1 }
 $r=$dialog.FileName
}
Write-Host "Starting R Shiny using $r"
& $r -e "shiny::runApp('.', launch.browser=TRUE)"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
