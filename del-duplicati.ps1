# Crea uno script che cerca file duplicati (stesso nome e stessa dimensione) all'interno di una cartella e ne elimina le copie.
# ===================== VERSIONE PER CANCELLARE DEFINITIVAMENTE ====================

# $sourcePath = "C:\Users\gabrielepergola\Downloads\ProvaPowershell\dir1"
 
# Get all files with same size
# $Files = Get-ChildItem -Path $sourcePath -File -Recurse | Sort-Object LastWriteTime -Descending | Group-Object -Property Length | Where-Object {$_.Count -gt 1}
 
# Group files by their hash and find duplicates
# $Duplicates = $Files | Select -ExpandProperty Group | Get-FileHash | Group-Object -Property Hash | Where-Object {$_.Count -gt 1}
 
# Delete the Duplicate files
# if ($duplicates.Count -eq 0) {
    # Write-Output "No duplicate files found."
# } else {
    # Write-Output "Duplicate files found and deleted:"
    # $duplicates | ForEach-Object {
        # $filesToDelete = $_.Group | Select-Object -Skip 1
        # $filesToDelete | ForEach-Object {
            # Write-Output "Deleting: $($_.Path)"
            # Remove-Item -Path $_.Path -Force
        # }
    # }
# }

# ====================== segue: VERSIONE PER SPOSTARE NEL CESTINO ==========================
# elimina sia copia, che copia (n)
$FolderPath = "C:\Users\pippo\Downloads\ProvaPowershell\dir1"

# Funzione per spostare i file nel cestino
function Move-ToRecycleBin {
    param (
        [string]$filePath
    )
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(10)
    $file = $shell.Namespace((Get-Item $filePath).DirectoryName).ParseName((Get-Item $filePath).Name)
    $recycleBin.MoveHere($file.Path, 0x100)
}

# Trova i file duplicati
$files = Get-ChildItem -Path $FolderPath -File

# Percorso del file di log per memorizzare i file spostati
$logFile = "C:\Temp\LogFile.txt"

# Itera attraverso i file e cerca duplicati
foreach ($file in $files) {
    if ($file.Name -match " - Copy(\s\(\d+\))?") {
        $originalName = $file.Name -replace " - Copy(\s\(\d+\))?", ""
        $originalFile = Get-ChildItem -Path $FolderPath -File | Where-Object { $_.Name -eq $originalName -and $_.Length -eq $file.Length }
        if ($originalFile) {
            # Se il file originale esiste, sposta la copia nel cestino
            $filePath = $file.FullName
            Add-Content -Path $logFile -Value $filePath
            Move-ToRecycleBin -filePath $filePath
            Write-host "File duplicato spostato nel cestino: $filePath"
        }
    }
}
