# Ottieni le informazioni su tutte le unità logiche
$drives = Get-PSDrive -PSProvider FileSystem

# Itera attraverso ciascuna unità e visualizza lo spazio libero
foreach ($drive in $drives) {
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    $totalSpaceGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
    $freeSpacePercentage = [math]::Round(($drive.Free / ($drive.Used + $drive.Free)) * 100, 2)
    
    Write-Host "Unità: $($drive.Name)"
    Write-Host "Spazio libero: $freeSpaceGB GB"
    Write-Host "Spazio totale: $totalSpaceGB GB"
    Write-Host "Percentuale di spazio libero: $freeSpacePercentage%"
    Write-Host "-----------------------------------"
    
    # Avviso se la memoria disponibile è sotto il 90%
    if ($freeSpacePercentage -lt 90) {
        Write-Host "ATTENZIONE: La memoria disponibile sull'unità $($drive.Name) è sotto il 90%!"
    }
}

Write-Host "Controllo dello spazio libero su disco completato."