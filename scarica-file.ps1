# URL del file da scaricare
$fileUrl = "https://en.wikipedia.org/wiki/Dependency_inversion_principle"

# Percorso della cartella di destinazione
$destinationFolder = "C:\Users\pippo\Downloads\ProvaPowershell\dir1"

# Nome del file da salvare
$fileName = "file.txt"

# Percorso completo del file di destinazione
$destinationPath = Join-Path -Path $destinationFolder -ChildPath $fileName

# Verifica se la cartella di destinazione esiste, altrimenti creala
if (-Not (Test-Path -Path $destinationFolder)) {
    New-Item -Path $destinationFolder -ItemType Directory
}

# Scarica il file da Internet e salvalo nella cartella di destinazione
Invoke-WebRequest -Uri $fileUrl -OutFile $destinationPath

Write-Host "Il file è stato scaricato e salvato in $destinationPath"
