# Specifica il percorso della directory
$directoryPath = "C:\Users\pippo\Downloads\ProvaPowershell"

# Ottieni tutti i file nella directory e nelle sottodirectory
$files = Get-ChildItem -Path $directoryPath -File -Recurse

# Crea un oggetto di tipo array per memorizzare i risultati
$result = @()

# Itera attraverso ogni file e ottieni la sua dimensione
foreach ($file in $files) {
    $fileInfo = [PSCustomObject]@{
        Nome = $file.Name
        Percorso = $file.FullName
        Dimensione = $file.Length
    }
    $result += $fileInfo
}

# Visualizza i risultati
$result | Format-Table -AutoSize
