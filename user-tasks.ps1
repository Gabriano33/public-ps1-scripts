# Crea un semplice "task manager" in PowerShell che elenca i processi e permette all’utente di terminarne uno digitando il suo ID.


# Crea uno script che simula il download di più file mostrando una barra di avanzamento personalizzata.
# Scrivi uno script che invia un'email automatica con un file allegato.




# Funzione per elencare i processi attivi.
function Elenca-Processi {
    Get-Process | Select-Object Id, ProcessName
}

# Funzione per terminare un processo dato il suo ID.
function Termina-Processo {
    param (
        [int]$ProcessId
    )
    try {
        Stop-Process -Id $ProcessId -Force
        Write-Output "Processo con ID $ProcessId terminato con successo."
    } catch {
        Write-Output "Errore: Impossibile terminare il processo con ID $ProcessId. Assicurati che l'ID sia corretto e che tu abbia i permessi necessari."
    }
}

# Script principale.
while ($true) {
    Clear-Host
    Write-Output "Task Manager Semplice"
    Write-Output "======================"
    Write-Output "Elenco dei processi attivi:"
    Elenca-Processi | Format-Table -AutoSize

    $input = Read-Host "Inserisci l'ID del processo da terminare (o 'exit' per uscire)"
    if ($input -eq 'exit') {
        break
    } elseif ($input -match '^\d+$') {
        $processId = [int]$input
        Termina-Processo -ProcessId $processId
    } else {
        Write-Output "Input non valido. Inserisci un ID numerico o 'exit' per uscire."
    }

    Start-Sleep -Seconds 3
}