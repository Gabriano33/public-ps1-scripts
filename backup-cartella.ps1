# Definisci il percorso della cartella di origine e della cartella di destinazione
$sourceFolder = "C:\Users\pippo\Downloads\ProvaPowershell\dir1"
$backupFolder = "C:\Users\pippo\Downloads\ProvaPowershell\dir3"

# Ottieni la data odierna nel formato AAAA-MM-GG
$date = Get-Date -Format "yyyy-MM-dd"

# Crea il nome della cartella di backup con la data odierna
$backupFolderName = "Backup_$date"
$backupFolderPath = Join-Path -Path $backupFolder -ChildPath $backupFolderName

# Verifica se la cartella di backup esiste, altrimenti creala
if (-Not (Test-Path -Path $backupFolderPath)) {
    New-Item -Path $backupFolderPath -ItemType Directory
}

# Copia tutti i file e le sottocartelle dalla cartella di origine alla cartella di backup
Copy-Item -Path $sourceFolder\* -Destination $backupFolderPath -Recurse -Force

Write-Host "Il backup della cartella $sourceFolder è stato creato in $backupFolderPath"
