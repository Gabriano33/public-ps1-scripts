# Nome del programma da verificare (es. notepad.exe)
$programName = "notepad.exe"
# Percorso completo del programma da avviare se non è in esecuzione
$programPath = "C:\Windows\System32\notepad.exe"

# Verifica se il programma è in esecuzione
$process = Get-Process -Name $programName -ErrorAction SilentlyContinue

if (-Not $process) {
    # Se il programma non è in esecuzione, avvialo
    Start-Process -FilePath $programPath
    Write-Host "$programName è stato avviato."
} else {
    Write-Host "$programName è già in esecuzione."
}