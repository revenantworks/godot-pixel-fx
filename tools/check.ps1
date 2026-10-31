# Pixel FX Starter checks on Windows: import, headless tests, render tests.
# Run from anywhere:
#   pwsh -File <this folder>\check.ps1 -Godot <full path to Godot .exe>
param(
    [Parameter(Mandatory = $true)][string]$Godot
)
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pixelfx-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $logDir | Out-Null

function Invoke-Step([string]$name, [string[]]$godotArgs) {
    $log = Join-Path $logDir "$name.log"
    $p = Start-Process -FilePath $Godot -ArgumentList $godotArgs -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    $text = (Get-Content $log -Raw) + (Get-Content "$log.err" -Raw)
    if ($text -match '(?m)^(ERROR|SCRIPT ERROR)|Parse Error') {
        Write-Host $text; throw "engine errors in step $name"
    }
    if ($name -ne 'import' -and $p.ExitCode -ne 0) { Write-Host $text; throw "step $name failed" }
    if ($name -ne 'import') { ($text -split "`n" | Where-Object { $_ -match '^(renderer|scripts)=?' }) | Write-Host }
}

Write-Host '== import';         Invoke-Step 'import'   @('--headless', '--path', $project, '--import')
Write-Host '== headless tests'; Invoke-Step 'headless' @('--headless', '--path', $project, '-s', 'res://tests/run_tests.gd')
Write-Host '== render tests';   Invoke-Step 'render'   @('--path', $project, '--audio-driver', 'Dummy', '-s', 'res://tests/run_tests.gd')
Write-Host 'all checks passed'
