# Trova tutti i file più grandi di 10KB in una cartella e nelle sue sottocartelle.
# Specifica la cartella da cui iniziare la ricerca
$folderPath = "C:\Users\pippo\Downloads\ProvaPowershell"

# Dimensione minima del file in byte (10KB)
$minSize = 10 * 1KB

# Funzione per trovare i file più grandi di una certa dimensione
function Find-LargeFiles {
    param (
        [string]$path,
        [int64]$sizeThreshold
    )
    Get-ChildItem -Path $path -Recurse -File | Where-Object { $_.Length -gt $sizeThreshold }
}

# Esegui la funzione e mostra i risultati
$largeFiles = Find-LargeFiles -path $folderPath -sizeThreshold $minSize
$largeFiles | ForEach-Object { Write-Output "$($_.FullName) - $([math]::Round($_.Length / 1KB, 2)) KB" }
