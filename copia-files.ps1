# Definisci il percorso della cartella di origine e della cartella di destinazione
$sourceFolder = "C:\Users\pippo\Downloads\ProvaPowershell\dir1"
$destinationFolder = "C:\Users\pippo\Downloads\ProvaPowershell\dir2"

# Verifica se la cartella di destinazione esiste, altrimenti creala
if (-Not (Test-Path -Path $destinationFolder)) {
    New-Item -Path $destinationFolder -ItemType Directory
}

# Copia tutti i file dalla cartella di origine alla cartella di destinazione
Get-ChildItem -Path $sourceFolder -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $destinationFolder -Force
}

Write-Host "Tutti i file sono stati copiati da $sourceFolder a $destinationFolder"
