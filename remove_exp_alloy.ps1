# Run as Administrator

# 1. Ferma e cancella il servizio Alloy, se presente
if (Get-Service -Name "Alloy" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "Alloy" -Force -ErrorAction SilentlyContinue
    sc.exe delete Alloy | Out-Null
    Start-Sleep -Seconds 1
}

# 2. Trova ed elimina install dir (modifica se hai path diversi)
$paths = @(
    "C:\Program Files\Grafana Alloy",
    "C:\Program Files\Alloy",
    "C:\ProgramData\alloy"
)
foreach ($p in $paths) {
    if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force }
}

# 3. (Facoltativo) Elimina eventuali installer temporanei
Remove-Item "$env:TEMP\alloy-installer*" -Force -ErrorAction SilentlyContinue

Write-Host "Alloy removed. No reboot required."