# Alloy Installation Script for Windows (Forces version 1.8.3)
# Run as Administrator in PowerShell 7+
# Modified: Specifica la v1.8.3, funzioni che puoi eventualmente togliere MARCATE IN COMMENTO

param(
    [string]$LokiEndpoint = "http://10.0.0.100:3100/loki/api/v1/push",
    [string]$PrometheusEndpoint = "http://10.0.0.100:9009/api/v1/push",
    [string]$LogPath = "C:\Temp\test.txt"
)

# Configuration
$ErrorActionPreference = "Stop"
$installDir = "C:\Program Files\GrafanaLabs\Alloy"
$configPath = "$installDir\config.alloy"
$serviceName = "Alloy"
$Version = "1.8.3"  # Forzata!

# Logging function (utile per diagnostica)
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# RIMOZIONE EXPORTERS: Se non usi node_exporter o windows_exporter su questa macchina, puoi COMMENTARE QUESTO BLOCCO
function Remove-Exporters {
    Write-Log "Removing existing exporters..." "INFO"
    $exporters = @("windows_exporter", "node_exporter")
    foreach ($exporter in $exporters) {
        try {
            $service = Get-Service -Name $exporter -ErrorAction SilentlyContinue
            if ($service) {
                Write-Log "Stopping and removing service: $exporter" "INFO"
                Stop-Service -Name $exporter -Force -ErrorAction SilentlyContinue
                sc.exe delete $exporter | Out-Null
                Write-Log "Service $exporter removed successfully" "INFO"
            } else {
                Write-Log "Service $exporter not found" "INFO"
            }
        } catch {
            Write-Log "Error removing $exporter : $($_.Exception.Message)" "WARN"
        }
    }
}

# -- BLOCCO DI FUNZIONI NON USATE Ora commentato --
#function Get-LatestVersion { ... (non usata più) }
#function Get-AvailableVersions { ... (non usata più) }
#function Test-VersionExists { ... (non usata più) }
# -------------------------------------------

# Download and install Alloy (mantengo la tolleranza sui nomi file)
function Install-Alloy {
    param([string]$AlloyVersion)

    Write-Log "Installing Alloy version $AlloyVersion..." "INFO"

    $installerZip = "$env:TEMP\alloy-installer-$AlloyVersion.zip"
    $installerExe = "$env:TEMP\alloy-installer-$AlloyVersion.exe"

    $urlPatterns = @(
        "https://github.com/grafana/alloy/releases/download/v$AlloyVersion/alloy-installer-windows-amd64.exe.zip",
        "https://github.com/grafana/alloy/releases/download/v$AlloyVersion/alloy-windows-amd64-installer.exe.zip"
    )

    $downloadSuccess = $false
    foreach ($url in $urlPatterns) {
        try {
            Write-Log "Trying download URL: $url" "INFO"
            Invoke-WebRequest -Uri $url -OutFile $installerZip -UseBasicParsing
            $downloadSuccess = $true
            break
        } catch {
            Write-Log "Download failed with URL: $url" "WARN"
            continue
        }
    }

    if (-not $downloadSuccess) {
        throw "Failed to download Alloy installer for version $AlloyVersion. Please verify the version exists."
    }

    Write-Log "Extracting installer..." "INFO"
    if (Test-Path $installerExe) { Remove-Item $installerExe -Force }

    Expand-Archive -LiteralPath $installerZip -DestinationPath $env:TEMP -Force

    $foundExe = Get-ChildItem "$env:TEMP" -Filter "*alloy*installer*.exe" | Select-Object -First 1

    if (-not $foundExe) {
        throw "Alloy installer executable not found after extraction!"
    }

    if ($foundExe.FullName -ne $installerExe) {
        Move-Item -Path $foundExe.FullName -Destination $installerExe -Force
    }

    Write-Log "Running installer silently..." "INFO"
    $installProcess = Start-Process -FilePath $installerExe -ArgumentList "/S", "/D=$installDir" -NoNewWindow -Wait -PassThru

    if ($installProcess.ExitCode -ne 0) {
        throw "Installer failed with exit code: $($installProcess.ExitCode)"
    }

    Remove-Item $installerZip, $installerExe -Force -ErrorAction SilentlyContinue

    Write-Log "Alloy installed successfully" "INFO"
}

function Write-AlloyConfig {
    Write-Log "Writing Alloy configuration..." "INFO"

    $logDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        Write-Log "Created log directory: $logDir" "INFO"
    }

    if (-not (Test-Path $LogPath)) {
        "Test log entry - $(Get-Date)" | Out-File -FilePath $LogPath -Encoding UTF8
    }

    $configContent = @"
logging {
    level = "info"
    format = "logfmt"
}

//====================== LOGS ======================

local.file_match "windows_logs" {
    path_targets = [{ 
        __path__ = "$($LogPath.Replace('\', '/'))",
        job = "windows-logs",
        instance = env("COMPUTERNAME")
    }]
}

loki.source.file "log_scrape" {
    targets = local.file_match.windows_logs.targets
    forward_to = [loki.write.send_to_loki.receiver]
    tail_from_end = true
}

loki.source.windowsevent "application" {
    eventlog_name = "Application"
    forward_to = [loki.write.send_to_loki.receiver]
}

loki.source.windowsevent "system" {
    eventlog_name = "System"
    forward_to = [loki.write.send_to_loki.receiver]
}

loki.write "send_to_loki" {
    endpoint {
        url = "$LokiEndpoint"
    }
    external_labels = {
        instance = env("COMPUTERNAME"),
        job = "alloy-windows",
    }
}

//====================== METRICS ======================

prometheus.exporter.windows "default" {
    enabled_collectors = [
        "cpu", "cs", "logical_disk", "memory",
        "net", "os", "service", "system", "process"
    ]
}

prometheus.scrape "windows_metrics" {
    targets = prometheus.exporter.windows.default.targets
    forward_to = [prometheus.remote_write.metrics_endpoint.receiver]
    scrape_interval = "30s"
}

prometheus.remote_write "metrics_endpoint" {
    endpoint {
        url = "$PrometheusEndpoint"
    }
    external_labels = {
        instance = env("COMPUTERNAME"),
        job = "alloy-windows-metrics",
    }
}
"@

    try {
        [System.IO.File]::WriteAllText($configPath, $configContent, [System.Text.Encoding]::UTF8)
        Write-Log "Configuration written to: $configPath" "INFO"
    } catch {
        throw "Failed to write configuration: $($_.Exception.Message)"
    }
}

function Start-AlloyService {
    Write-Log "Starting Alloy service..." "INFO"

    try {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Write-Log "Restarting Alloy service..." "INFO"
                Restart-Service -Name $serviceName -Force
            } else {
                Start-Service -Name $serviceName
            }
            Write-Log "Alloy service started successfully" "INFO"
        } else {
            Write-Log "Alloy service not found. Please check installation." "ERROR"
        }
    } catch {
        Write-Log "Failed to start Alloy service: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Main {
    try {
        Write-Log "=== Starting Alloy Installation ===" "INFO"
        Write-Log "Fixed Version: $Version" "INFO"
        Write-Log "Loki Endpoint: $LokiEndpoint" "INFO"
        Write-Log "Prometheus Endpoint: $PrometheusEndpoint" "INFO"

        if (-not (Test-Administrator)) {
            throw "This script must be run as Administrator"
        }

        # Skipping version check - forcibly using 1.8.3!
        Write-Log "Installing version: $Version" "INFO"

        Remove-Exporters
        Install-Alloy -AlloyVersion $Version
        Write-AlloyConfig
        Start-AlloyService

        Write-Log "=== Installation completed successfully! ===" "INFO"
        Write-Log "Alloy version $Version is now running and configured to send data to:" "INFO"
        Write-Log "  - Logs: $LokiEndpoint" "INFO"
        Write-Log "  - Metrics: $PrometheusEndpoint" "INFO"

    } catch {
        Write-Log "Installation failed: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

Main