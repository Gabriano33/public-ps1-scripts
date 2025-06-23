# Scrivi uno script che confronta il contenuto di due cartelle e segnala le differenze.

# Definisci i percorsi delle due cartelle da confrontare.
$folder1 = "C:\Users\gabrielepergola\Downloads\ProvaPowershell\dir1"
$folder2 = "C:\Users\gabrielepergola\Downloads\ProvaPowershell\dir2"

# Definisci il percorso del file di output nella stessa cartella dello script.
$outputFile = "$PSScriptRoot\differenze-cartelle.txt"

# Ottieni l'elenco dei file nelle due cartelle.
$files1 = Get-ChildItem -Path $folder1 -Recurse | Select-Object -Property Name
$files2 = Get-ChildItem -Path $folder2 -Recurse | Select-Object -Property Name

# Confronta i file nelle due cartelle basandosi solo sui nomi dei file.
$compare = Compare-Object -ReferenceObject $files1 -DifferenceObject $files2 -Property Name

# Inizializza il file di output.
Clear-Content -Path $outputFile

# Scrivi le differenze nel file di output in modo leggibile.
foreach ($difference in $compare) {
    if ($difference.SideIndicator -eq "<=") {
        $outputString = "Solo in $folder1 =`n$($difference.Name)`n"
    } elseif ($difference.SideIndicator -eq "=>") {
        $outputString = "Solo in $folder2 =`n$($difference.Name)`n"
    } else {
        $outputString = "Differenza =`n$($difference.Name)`n"
    }
    $outputString | Out-File -FilePath $outputFile -Append
}

# Stampa un messaggio di conferma.
Write-Output "Confronto completato. I risultati sono stati salvati in $outputFile."