# Specifica il percorso della directory
$directoryPath = "C:\percorso\della\directory"

# Ottieni tutti i file nella directory e nelle sottodirectory
$files = Get-ChildItem -Path $directoryPath -File -Recurse

# Funzione per convertire la dimensione dei file
function Convert-Size {
    param (
        [int64]$bytes
    )
    if ($bytes -ge 1GB) {
        return "{0:N2} GB" -f ($bytes / 1GB)
    } elseif ($bytes -ge 1MB) {
        return "{0:N2} MB" -f ($bytes / 1MB)
    } elseif ($bytes -ge 1KB) {
        return "{0:N2} KB" -f ($bytes / 1KB)
    } else {
        return "$bytes B"
    }
}

# Crea un oggetto per memorizzare i risultati
$result = @()

# Itera attraverso ogni file e ottieni la sua dimensione
foreach ($file in $files) {
    $fileInfo = [PSCustomObject]@{
        Nome = $file.Name
        Percorso = $file.FullName
        Dimensione = Convert-Size -bytes $file.Length
    }
    $result += $fileInfo
}

# Visualizza i risultati
$result | Format-Table -AutoSize