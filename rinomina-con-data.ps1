# Scrivi uno script che rinomina automaticamente tutti i file di una cartella aggiungendo la data al nome.

# Specifica la cartella contenente i file da rinominare
$folderPath = "C:\Users\gabrielepergola\Downloads\ProvaPowershell\dir1"

# Ottieni la data corrente nel formato desiderato (ad esempio, DDMMYYYY)
$date = Get-Date -Format "dd.MM.yyyy"

# Funzione per rinominare i file aggiungendo la data al nome
function Rename-FilesWithDate {
    param (
        [string]$path,
        [string]$date
    )
    Get-ChildItem -Path $path -File | ForEach-Object {
        $newName = "$($_.BaseName)_$date$($_.Extension)"
        Rename-Item -Path $_.FullName -NewName $newName
    }
}

# Esegui la funzione per rinominare i file
Rename-FilesWithDate -path $folderPath -date $date