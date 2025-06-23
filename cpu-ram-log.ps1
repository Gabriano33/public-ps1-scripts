# Monitora l’uso della RAM e della CPU ogni 10 secondi e salva i dati in un file di log.
 

# Ottieni la quantità totale di RAM
$totalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum

# Definisci il percorso del file di output nella stessa cartella dello script
$outputFile = "$PSScriptRoot\log-ram-cpu.txt"

# Funzione per monitorare e registrare l'uso della RAM e della CPU
function Log-RamCpuUsage {
    while ($true) {
        # Ottieni la data e l'ora corrente
        $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Ottieni il tempo della CPU
        $cpuTime = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue

        # Ottieni la memoria disponibile
        $availMem = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue

        # Prepara la stringa di output
        $outputString = $date + ' > CPU: ' + $cpuTime.ToString("#,0.000") + '%, Avail. Mem.: ' + $availMem.ToString("N0") + 'MB (' + (104857600 * $availMem / $totalRam).ToString("#,0.0") + '%)'

        # Scrivi la stringa di output nel file
        $outputString | Out-File -FilePath $outputFile -Append

        # Attendi 10 secondi prima di ripetere
        Start-Sleep -Seconds 10
    }
}

# Esegui la funzione per iniziare il monitoraggio
Log-RamCpuUsage