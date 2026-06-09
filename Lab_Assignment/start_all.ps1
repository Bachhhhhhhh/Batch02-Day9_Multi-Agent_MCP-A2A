# Start all Legal Multi-Agent System services in separate windows
$LocalPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
$ParentPython = Join-Path (Split-Path $PSScriptRoot -Parent) ".venv\Scripts\python.exe"

if (Test-Path $LocalPython) {
    $Python = $LocalPython
} elseif (Test-Path $ParentPython) {
    $Python = $ParentPython
} else {
    $Python = "python"
}

$Run = "& `"$Python`""

Write-Host "Starting Registry service on port 10000..."
Start-Process powershell -WorkingDirectory $PSScriptRoot -ArgumentList "-NoExit -Command `"$Run -m registry`""

Start-Sleep -Seconds 2

Write-Host "Starting Criminal Agent on port 10102..."
Start-Process powershell -WorkingDirectory $PSScriptRoot -ArgumentList "-NoExit -Command `"$Run -m criminal_agent`""

Write-Host "Starting Rehab Agent on port 10103..."
Start-Process powershell -WorkingDirectory $PSScriptRoot -ArgumentList "-NoExit -Command `"$Run -m rehab_agent`""

Start-Sleep -Seconds 3

Write-Host "Starting Law Agent on port 10101..."
Start-Process powershell -WorkingDirectory $PSScriptRoot -ArgumentList "-NoExit -Command `"$Run -m law_agent`""

Start-Sleep -Seconds 3

Write-Host "Starting Customer Agent on port 10100..."
Start-Process powershell -WorkingDirectory $PSScriptRoot -ArgumentList "-NoExit -Command `"$Run -m customer_agent`""

Start-Sleep -Seconds 2

Write-Host "Starting Observatory UI on port 8000..."
Start-Process powershell -WorkingDirectory $PSScriptRoot -ArgumentList "-NoExit -Command `"$Run app.py`""

Write-Host ""
Write-Host "All services started in separate windows."
Write-Host "Open http://127.0.0.1:8000 to use the live graph and trace log."
