# Trova tutte le porte TCP aperte sul tuo computer e salva l’elenco in un file di testo.

# Definisci il percorso del file di output nella stessa cartella dello script.
$outputFile = "$PSScriptRoot\elenco-porte-tcp.txt"

# Ottieni tutte le connessioni TCP attive.
$connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' }

# Ottieni la data e l'ora corrente.
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Scrivi le porte aperte nel file di output con la data e l'ora corrente.
foreach ($connection in $connections) {
    $outputString = "$date - La porta $($connection.LocalPort) e' aperta."
    $outputString | Out-File -FilePath $outputFile -Append
}