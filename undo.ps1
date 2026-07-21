# VirtualBox Configuration Undo Script - PowerShell Version

param(
    [Parameter(Mandatory=$true)]
    [string]$VMName
)

$ErrorActionPreference = "Stop"

# Color output
function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Write-Section {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script requires administrator privileges. Please run as Administrator."
    exit 1
}

# Find VBoxManage.exe
$VBoxManagePaths = @(
    "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe",
    "C:\Program Files (x86)\Oracle\VirtualBox\VBoxManage.exe"
)

$VBoxManage = $null
foreach ($path in $VBoxManagePaths) {
    if (Test-Path $path) {
        $VBoxManage = $path
        break
    }
}

if (-not $VBoxManage) {
    Write-Error "VBoxManage.exe not found. Please ensure VirtualBox is installed."
    exit 1
}

# Check if VM exists
try {
    & $VBoxManage showvminfo "$VMName" | Out-Null
} catch {
    Write-Error "VM '$VMName' not found."
    exit 1
}

# Check VM state
function Test-VMPoweredOff {
    $vminfo = & $VBoxManage showvminfo "$VMName" --machinereadable
    $state = ($vminfo | Select-String "^VMState=").ToString().Split('"')[1]
    
    if ($state -ne "poweroff" -and $state -ne "aborted") {
        Write-Error "VM must be powered off. Current state: $state"
        exit 1
    }
}

# Backup current settings
function Backup-VMSettings {
    $backupDir = "$env:TEMP\vbox_backups"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $cleanVMName = $VMName -replace ' ', '_'
    $backupFile = Join-Path $backupDir "vbox_backup_${cleanVMName}_${timestamp}.txt"
    
    Write-Info "Backing up current settings to: $backupFile"
    
    $backupContent = @"
=== VM Configuration Backup ===
Timestamp: $(Get-Date)
VM Name: $VMName

=== Hardware UUID ===
$((& $VBoxManage showvminfo "$VMName" --machinereadable) | Select-String "^hardwareuuid=")

=== MAC Addresses ===
$((& $VBoxManage showvminfo "$VMName" --machinereadable) | Select-String "^macaddress")

=== Paravirtualization ===
$((& $VBoxManage showvminfo "$VMName" --machinereadable) | Select-String "^paravirtprovider=")

=== Graphics Controller ===
$((& $VBoxManage showvminfo "$VMName" --machinereadable) | Select-String "^graphicscontroller=")

=== All Extra Data ===
"@
    
    $backupContent | Out-File -FilePath $backupFile -Encoding UTF8
    $extraData = & $VBoxManage getextradata "$VMName" enumerate
    $extraData | Out-File -FilePath $backupFile -Encoding UTF8 -Append
    
    Write-Success "Backup saved to: $backupFile"
}

function Undo-VMIdentifiers {
    Write-Section "Reverting to VirtualBox Defaults"
    Test-VMPoweredOff
    Backup-VMSettings
    
    Write-Info "Removing all custom configuration..."
    
    # Remove all VBoxInternal extradata
    $extraData = & $VBoxManage getextradata "$VMName" enumerate
    $extraData | Select-String "^Key: VBoxInternal" | ForEach-Object {
        $key = $_ -replace "^Key: ([^,]+).*", '$1'
        if ($key) {
            & $VBoxManage setextradata "$VMName" $key "" 2>$null | Out-Null
        }
    }
    
    # Reset MAC addresses
    Write-Info "Resetting network adapters..."
    for ($i = 1; $i -le 8; $i++) {
        & $VBoxManage modifyvm "$VMName" --macaddress${i} auto 2>$null | Out-Null
    }
    
    # Reset UUID
    Write-Info "Generating new UUID..."
    $newUUID = [guid]::NewGuid().ToString()
    & $VBoxManage modifyvm "$VMName" --hardware-uuid $newUUID
    
    # Restore paravirtualization
    & $VBoxManage modifyvm "$VMName" --paravirtprovider default 2>$null | Out-Null
    
    # Restore graphics
    & $VBoxManage modifyvm "$VMName" --graphicscontroller vboxsvga 2>$null | Out-Null
    
    # Restore CPU settings
    & $VBoxManage modifyvm "$VMName" --cpu-execution-cap 100 2>$null | Out-Null
    & $VBoxManage modifyvm "$VMName" --hpet on 2>$null | Out-Null
    
    Write-Success "VM reverted to VirtualBox defaults"
}

# Main execution
Undo-VMIdentifiers
