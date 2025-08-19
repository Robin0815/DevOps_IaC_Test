# Native Windows CI/CD Pipeline Setup with Docker Desktop
# Run the complete CI/CD pipeline directly on Windows using Docker Desktop

param(
    [switch]$Force,
    [switch]$SkipChecks
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"

function Write-Header {
    param([string]$Message)
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

Write-Header "Native Windows CI/CD Pipeline Setup with Docker Desktop"

Write-Host @"
This script sets up the complete CI/CD pipeline on Windows using Docker Desktop.

✅ What you get:
   - Forgejo Git server running locally
   - Gitea Actions CI/CD runner
   - ArgoCD for GitOps deployments
   - Local container registry
   - Optional monitoring (Prometheus + Grafana)

🪟 System Requirements:
   - Windows 10/11 (64-bit)
   - 8GB+ RAM (16GB recommended)
   - 20GB+ free disk space
   - Internet connection
   - Administrator privileges (for initial setup)

🐳 Docker Desktop Features:
   - WSL2 backend (best performance)
   - Kubernetes integration
   - GUI management interface
   - Resource monitoring

"@

if (-not $Force) {
    $continue = Read-Host "Continue with Windows Docker Desktop setup? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "Setup cancelled."
        exit 0
    }
}

# Check if running on Windows
if ($PSVersionTable.Platform -and $PSVersionTable.Platform -ne "Win32NT") {
    Write-Error "This script is for Windows only"
    exit 1
}

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $SkipChecks) {
    # Check system requirements
    Write-Header "System Requirements Check"

    # Check RAM
    $totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    if ($totalRAM -lt 8) {
        Write-Warning "System has ${totalRAM}GB RAM. 8GB+ recommended for optimal performance."
        $continueRAM = Read-Host "Continue anyway? (y/N)"
        if ($continueRAM -ne "y" -and $continueRAM -ne "Y") {
            exit 0
        }
    } else {
        Write-Success "System RAM: ${totalRAM}GB ✓"
    }

    # Check disk space
    $freeSpace = [math]::Round((Get-PSDrive C).Free / 1GB)
    if ($freeSpace -lt 20) {
        Write-Warning "Available disk space: ${freeSpace}GB. 20GB+ recommended."
        $continueDisk = Read-Host "Continue anyway? (y/N)"
        if ($continueDisk -ne "y" -and $continueDisk -ne "Y") {
            exit 0
        }
    } else {
        Write-Success "Available disk space: ${freeSpace}GB ✓"
    }

    # Check Windows version
    $winVersion = [System.Environment]::OSVersion.Version
    if ($winVersion.Major -lt 10) {
        Write-Error "Windows 10 or later required"
        exit 1
    }
    Write-Success "Windows version: $($winVersion.Major).$($winVersion.Minor) ✓"
}

# Install dependencies
Write-Header "Installing Dependencies"

# Check if Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Chocolatey package manager..."
    if (-not $isAdmin) {
        Write-Error "Administrator privileges required to install Chocolatey"
        Write-Host "Please run this script as Administrator or install Chocolatey manually:"
        Write-Host "https://chocolatey.org/install"
        exit 1
    }
    
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Success "Chocolatey already installed"
}

# Install required tools
$requiredTools = @(
    "docker-desktop",
    "git",
    "make",
    "curl",
    "jq"
)

foreach ($tool in $requiredTools) {
    Write-Info "Checking $tool..."
    $installed = choco list --local-only | Select-String $tool
    if (-not $installed) {
        Write-Info "Installing $tool..."
        if ($isAdmin) {
            choco install $tool -y
        } else {
            Write-Warning "$tool not found. Please install manually or run as Administrator"
        }
    } else {
        Write-Success "$tool already installed"
    }
}

# Check if Docker Desktop is running
Write-Header "Checking Docker Desktop"
$dockerRunning = $false
try {
    docker info | Out-Null
    $dockerRunning = $true
    Write-Success "Docker Desktop is running"
} catch {
    Write-Warning "Docker Desktop is not running or not installed"
}

if (-not $dockerRunning) {
    Write-Info "Please ensure Docker Desktop is installed and running:"
    Write-Host "1. Install Docker Desktop from https://www.docker.com/products/docker-desktop"
    Write-Host "2. Start Docker Desktop"
    Write-Host "3. Wait for it to be ready (whale icon in system tray)"
    Write-Host "4. Run this script again"
    
    $startDocker = Read-Host "Would you like to try starting Docker Desktop now? (y/N)"
    if ($startDocker -eq "y" -or $startDocker -eq "Y") {
        Write-Info "Attempting to start Docker Desktop..."
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -WindowStyle Hidden
        Write-Info "Waiting for Docker Desktop to start (this may take 2-3 minutes)..."
        
        $timeout = 180 # 3 minutes
        $elapsed = 0
        while ($elapsed -lt $timeout) {
            try {
                docker info | Out-Null
                Write-Success "Docker Desktop is now running!"
                $dockerRunning = $true
                break
            } catch {
                Start-Sleep 10
                $elapsed += 10
                Write-Host "." -NoNewline
            }
        }
        
        if (-not $dockerRunning) {
            Write-Error "Docker Desktop failed to start within timeout"
            exit 1
        }
    } else {
        exit 1
    }
}

# Enable WSL2 backend (if available)
Write-Info "Checking WSL2 backend..."
$wslEnabled = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wslEnabled.State -eq "Enabled") {
    Write-Success "WSL2 is available (recommended for best performance)"
} else {
    Write-Warning "WSL2 not enabled. Docker Desktop will use Hyper-V backend"
}

# Check port availability
Write-Header "Checking Port Availability"
$requiredPorts = @(3000, 8080, 5000, 9090, 3001)
$portsInUse = @()

foreach ($port in $requiredPorts) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connection) {
        $portsInUse += $port
        Write-Warning "Port $port is in use"
    } else {
        Write-Success "Port $port is available"
    }
}

if ($portsInUse.Count -gt 0) {
    Write-Host ""
    Write-Host "The following ports are in use: $($portsInUse -join ', ')"
    Write-Host "You can:"
    Write-Host "1. Stop services using these ports"
    Write-Host "2. Continue anyway (may cause conflicts)"
    Write-Host "3. Exit and free the ports manually"
    Write-Host ""
    $continuePorts = Read-Host "Continue anyway? (y/N)"
    if ($continuePorts -ne "y" -and $continuePorts -ne "Y") {
        Write-Host ""
        Write-Host "To find what's using a port: netstat -ano | findstr :PORT"
        Write-Host "To kill a process: taskkill /PID <PID> /F"
        exit 0
    }
}

# Configure Docker for insecure registry
Write-Header "Configuring Docker Desktop"
$dockerConfigPath = "$env:USERPROFILE\.docker\daemon.json"
$dockerConfigDir = Split-Path $dockerConfigPath -Parent

if (-not (Test-Path $dockerConfigDir)) {
    New-Item -ItemType Directory -Path $dockerConfigDir -Force | Out-Null
}

$dockerConfig = @{
    "insecure-registries" = @("localhost:5000")
    "experimental" = $false
}

if (Test-Path $dockerConfigPath) {
    Copy-Item $dockerConfigPath "$dockerConfigPath.backup"
    Write-Info "Backed up existing Docker configuration"
}

$dockerConfig | ConvertTo-Json | Set-Content $dockerConfigPath
Write-Success "Docker configured for local registry"

Write-Warning "Docker Desktop needs to restart to apply configuration changes"
Write-Host "Please restart Docker Desktop:"
Write-Host "1. Right-click Docker whale icon in system tray"
Write-Host "2. Select 'Restart Docker Desktop'"
Write-Host "3. Wait for Docker to restart completely"
Write-Host ""
Read-Host "Press Enter after Docker has restarted..."

# Verify Docker is running again
try {
    docker info | Out-Null
    Write-Success "Docker restarted successfully"
} catch {
    Write-Error "Docker is not running after restart. Please start Docker Desktop."
    exit 1
}

# Set up project
Write-Header "Setting Up CI/CD Pipeline"

# Create directories
Write-Info "Creating project directories..."
$directories = @("data\forgejo", "data\runner", "data\argocd", "data\registry", "data\prometheus", "data\grafana", "config", "backups")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Copy Prometheus configuration
if (Test-Path "config\prometheus.yml.example") {
    Copy-Item "config\prometheus.yml.example" "config\prometheus.yml"
    Write-Success "Prometheus configuration ready"
}

# Pull Docker images
Write-Info "Pulling Docker images (this may take a few minutes)..."
$images = @(
    "codeberg.org/forgejo/forgejo:1.21",
    "gitea/act_runner:latest",
    "quay.io/argoproj/argocd:v2.9.3",
    "registry:2",
    "prom/prometheus:latest",
    "grafana/grafana:latest"
)

foreach ($image in $images) {
    Write-Info "Pulling $image..."
    docker pull $image
}

Write-Success "All Docker images pulled"

# Start the services
Write-Header "Starting CI/CD Pipeline"
Write-Info "Starting services with Docker Compose..."

try {
    if (Get-Command make -ErrorAction SilentlyContinue) {
        make start
    } else {
        docker-compose up -d
    }
    Write-Success "Services started successfully!"
} catch {
    Write-Error "Failed to start services. Check the logs above."
    exit 1
}

# Wait for services to be ready
Write-Info "Waiting for services to be ready (this may take 2-3 minutes)..."
Start-Sleep 30

# Check service status
Write-Header "Service Status Check"
$servicesReady = $true

# Check Forgejo
try {
    Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5 | Out-Null
    Write-Success "Forgejo is ready at http://localhost:3000"
} catch {
    Write-Warning "Forgejo not ready yet (may need more time)"
    $servicesReady = $false
}

# Check ArgoCD
try {
    Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5 | Out-Null
    Write-Success "ArgoCD is ready at http://localhost:8080"
} catch {
    Write-Warning "ArgoCD not ready yet (may need more time)"
    $servicesReady = $false
}

# Check Registry
try {
    Invoke-WebRequest -Uri "http://localhost:5000/v2/" -UseBasicParsing -TimeoutSec 5 | Out-Null
    Write-Success "Registry is ready at http://localhost:5000"
} catch {
    Write-Warning "Registry not ready yet (may need more time)"
    $servicesReady = $false
}

if (-not $servicesReady) {
    Write-Host ""
    Write-Info "Some services are still starting up. This is normal."
    Write-Host "Run 'make status' or 'docker-compose ps' in a few minutes to check again."
}

# Create helpful shortcuts and scripts
Write-Header "Setting Up Convenience Features"

# Create PowerShell profile with aliases
$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$aliases = @"

# CI/CD Pipeline aliases
function cicd-start { Set-Location '$PWD'; make start }
function cicd-stop { Set-Location '$PWD'; make stop }
function cicd-status { Set-Location '$PWD'; make status }
function cicd-logs { Set-Location '$PWD'; make logs }
function cicd-clean { Set-Location '$PWD'; make clean }
function cicd-backup { Set-Location '$PWD'; make backup }

# Set aliases
Set-Alias -Name cstart -Value cicd-start
Set-Alias -Name cstop -Value cicd-stop
Set-Alias -Name cstatus -Value cicd-status
Set-Alias -Name clogs -Value cicd-logs

"@

if (Test-Path $profilePath) {
    $existingProfile = Get-Content $profilePath -Raw
    if ($existingProfile -notmatch "CI/CD Pipeline aliases") {
        Add-Content $profilePath $aliases
        Write-Success "Aliases added to PowerShell profile"
    } else {
        Write-Success "Aliases already exist in PowerShell profile"
    }
} else {
    Set-Content $profilePath $aliases
    Write-Success "PowerShell profile created with aliases"
}

# Create desktop shortcuts
Write-Info "Creating desktop shortcuts..."
$desktopPath = [Environment]::GetFolderPath("Desktop")
$serviceInfoPath = Join-Path $desktopPath "CI_CD_Services_Windows.txt"

$serviceInfo = @"
CI/CD Pipeline Services - Native Windows with Docker Desktop
===========================================================

Service URLs:
- Forgejo (Git):     http://localhost:3000
- ArgoCD (CD):       http://localhost:8080
- Registry:          http://localhost:5000
- Prometheus:        http://localhost:9090 (if monitoring enabled)
- Grafana:           http://localhost:3001 (if monitoring enabled)

Project Location: $PWD

Quick Commands (PowerShell):
- Start:    cicd-start    (or make start)
- Stop:     cicd-stop     (or make stop)
- Status:   cicd-status   (or make status)
- Logs:     cicd-logs     (or make logs)
- Backup:   cicd-backup   (or make backup)

Docker Desktop:
- Open Docker Desktop from Start Menu
- View containers and logs in GUI
- Monitor resource usage
- Access container shells

Next Steps:
1. Configure Forgejo: http://localhost:3000
2. Get ArgoCD password: make argocd-password
3. Follow Quick Start Guide: docs\quick-start-guide.md

Documentation: $PWD\docs\
"@

Set-Content $serviceInfoPath $serviceInfo
Write-Success "Service information saved to Desktop"

# Create batch files for easy access
$batchDir = Join-Path $PWD "scripts"
if (-not (Test-Path $batchDir)) {
    New-Item -ItemType Directory -Path $batchDir -Force | Out-Null
}

# Start script
$startScript = @"
@echo off
cd /d "$PWD"
echo Starting CI/CD Pipeline...
make start
pause
"@
Set-Content (Join-Path $batchDir "start-cicd.bat") $startScript

# Stop script
$stopScript = @"
@echo off
cd /d "$PWD"
echo Stopping CI/CD Pipeline...
make stop
pause
"@
Set-Content (Join-Path $batchDir "stop-cicd.bat") $stopScript

Write-Success "Batch scripts created in scripts\ directory"

# Final success message
Write-Header "🎉 Native Windows Setup with Docker Desktop Complete!"
Write-Host ""
Write-Host "Your CI/CD pipeline is running natively on Windows with Docker Desktop!"
Write-Host ""
Write-Host "📊 Access your services:"
Write-Host "   Forgejo:  http://localhost:3000"
Write-Host "   ArgoCD:   http://localhost:8080"
Write-Host "   Registry: http://localhost:5000"
Write-Host ""
Write-Host "🚀 Quick commands (PowerShell):"
Write-Host "   cicd-start    # Start all services"
Write-Host "   cicd-stop     # Stop all services"
Write-Host "   cicd-status   # Check service status"
Write-Host "   cicd-logs     # View service logs"
Write-Host ""
Write-Host "🪟 Windows features:"
Write-Host "   - Docker Desktop GUI for container management"
Write-Host "   - PowerShell aliases for convenience"
Write-Host "   - Batch scripts in scripts\ directory"
Write-Host "   - Desktop shortcuts and service info"
Write-Host ""
Write-Host "📋 Next steps:"
Write-Host "   1. Configure Forgejo (create admin account)"
Write-Host "   2. Get ArgoCD password: make argocd-password"
Write-Host "   3. Follow the Quick Start Guide: docs\quick-start-guide.md"
Write-Host ""
Write-Host "📚 Documentation: $PWD\docs\"
Write-Host "💾 Service info saved to Desktop: CI_CD_Services_Windows.txt"
Write-Host ""

# Optional monitoring setup
Write-Host ""
$enableMonitoring = Read-Host "Would you like to enable monitoring (Prometheus + Grafana)? (y/N)"
if ($enableMonitoring -eq "y" -or $enableMonitoring -eq "Y") {
    Write-Info "Starting monitoring stack..."
    if (Get-Command make -ErrorAction SilentlyContinue) {
        make start-monitoring
    } else {
        docker-compose --profile monitoring up -d
    }
    Write-Host ""
    Write-Success "Monitoring enabled!"
    Write-Host "   Prometheus: http://localhost:9090"
    Write-Host "   Grafana:    http://localhost:3001 (admin/admin)"
}

Write-Success "Setup complete! Your native Windows CI/CD pipeline with Docker Desktop is ready to use."
Write-Host ""
Write-Host "🔄 To reload PowerShell aliases: . `$PROFILE"
Write-Host "🐳 Access Docker Desktop from the system tray or Start Menu"