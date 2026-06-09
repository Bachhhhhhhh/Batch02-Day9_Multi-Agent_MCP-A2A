# Start all Legal Multi-Agent System services in separate windows
Write-Host "Starting Registry service on port 10000..."
Start-Process powershell -ArgumentList "-NoExit -Command `"uv run python -m registry`""

Start-Sleep -Seconds 2

Write-Host "Starting Tax Agent on port 10102..."
Start-Process powershell -ArgumentList "-NoExit -Command `"uv run python -m tax_agent`""

Write-Host "Starting Compliance Agent on port 10103..."
Start-Process powershell -ArgumentList "-NoExit -Command `"uv run python -m compliance_agent`""

Start-Sleep -Seconds 3

Write-Host "Starting Law Agent on port 10101..."
Start-Process powershell -ArgumentList "-NoExit -Command `"uv run python -m law_agent`""

Start-Sleep -Seconds 3

Write-Host "Starting Customer Agent on port 10100..."
Start-Process powershell -ArgumentList "-NoExit -Command `"uv run python -m customer_agent`""

Write-Host ""
Write-Host "All services started in separate windows."
Write-Host "Now run test_client.py to send a query:"
Write-Host "  uv run python test_client.py"
