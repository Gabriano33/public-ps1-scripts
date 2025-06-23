# Ottieni la directory corrente
$currentDirectory = Get-Location

# Specifica il nome della nuova cartella
$newFolderName = "NuovaCartella"

# Crea la nuova cartella
New-Item -Path $currentDirectory -Name $newFolderName -ItemType Directory

# Attendi 10 secondi
Start-Sleep -Seconds 10

# Cancella la cartella
Remove-Item -Path "$currentDirectory\$newFolderName" -Recurse