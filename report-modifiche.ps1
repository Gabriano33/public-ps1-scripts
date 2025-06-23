# Set the folder to monitor
$folderToWatch = "C:\Users\gabrielepergola\Downloads\ProvaPowershell"

# Set the log file path
$logFile = "$PSScriptRoot\activity-report.txt"

# Ensure the log file exists
if (!(Test-Path $logFile)) {
    New-Item -ItemType File -Path $logFile -Force | Out-Null
}

# Function to write logs
function Write-Log {
    param ($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
    Write-Host "$timestamp - $message"
}

# Get initial state (Ensure it is not null)
$previousState = Get-ChildItem -Path $folderToWatch -Recurse | Select-Object FullName, LastWriteTime

Write-Host "Monitoring $folderToWatch... Press Ctrl+C to stop."

while ($true) {
    Start-Sleep -Seconds 2  # Adjust the interval as needed

    # Get the new state of the folder
    $currentState = Get-ChildItem -Path $folderToWatch -Recurse | Select-Object FullName, LastWriteTime

    # Ensure we have an initial state before comparison
    if ($previousState) {
        # Compare objects
        $newFiles = Compare-Object -ReferenceObject $previousState -DifferenceObject $currentState -Property FullName -PassThru | Where-Object { $_.SideIndicator -eq "=>" }
        $deletedFiles = Compare-Object -ReferenceObject $previousState -DifferenceObject $currentState -Property FullName -PassThru | Where-Object { $_.SideIndicator -eq "<=" }

        # Log new files
        foreach ($file in $newFiles) {
            Write-Log "New file added: $($file.FullName)"
        }

        # Log deleted files
        foreach ($file in $deletedFiles) {
            Write-Log "File deleted: $($file.FullName)"
        }
    }

    # Update the state for the next loop iteration
    $previousState = $currentState
}
