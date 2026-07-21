##################################################
# VirtualBox VM Stealth Configuration - PowerShell Version
# Tested on VirtualBox 7.2.2
# Run BEFORE starting the VM (VM must be powered off)
# Usage: .\vbox_stealth.ps1 -VMName "VM_NAME" -Preset [dell|hp|lenovo|asus]
##################################################

param(
    [Parameter(Mandatory=$true)]
    [string]$VMName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("dell", "hp", "lenovo", "asus")]
    [string]$Preset = "dell"
)

# Enable error handling
$ErrorActionPreference = "Stop"

# Color output
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
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
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
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

# Verify VirtualBox can find the VM
try {
    & $VBoxManage showvminfo "$VMName" | Out-Null
} catch {
    Write-Error "VM '$VMName' not found."
    Write-Host ""
    Write-Host "Available VMs:"
    & $VBoxManage list vms
    exit 1
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "VirtualBox VM Stealth Configuration - PowerShell Version v7.2.2" -ForegroundColor Cyan
Write-Host "Tested with Windows 10 VM, may work for other stuff too idk" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "VM: $VMName" -ForegroundColor White
Write-Host "Preset: $Preset" -ForegroundColor White
Write-Host ""

# Generate random serials
function New-RandomSerial {
    param([int]$Length = 10)
    -join ((65..90) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_})
}

$SYSTEM_SERIAL = New-RandomSerial -Length 10
$BOARD_SERIAL = New-RandomSerial -Length 8
$CHASSIS_SERIAL = New-RandomSerial -Length 8
$DISK_SERIAL = New-RandomSerial -Length 20

# Preset configurations
switch ($Preset) {
    "dell" {
        $BIOS_VENDOR = "American Megatrends Inc."
        $BIOS_VERSION = "2.18.0"
        $BIOS_RELEASE_DATE = "12/15/2022"
        $SYSTEM_VENDOR = "Dell Inc."
        $SYSTEM_PRODUCT = "OptiPlex 7090"
        $BOARD_PRODUCT = "0J42H4"
        $DISK_MODEL = "Samsung SSD 870 EVO 500GB"
        $ACPI_OEM_ID = "DELL  "
    }
    "hp" {
        $BIOS_VENDOR = "HP"
        $BIOS_VERSION = "T83 v02.08"
        $BIOS_RELEASE_DATE = "10/28/2022"
        $SYSTEM_VENDOR = "HP"
        $SYSTEM_PRODUCT = "HP EliteDesk 800 G6"
        $BOARD_PRODUCT = "872E"
        $DISK_MODEL = "WDC WD5000AAKX-60U6AA0"
        $ACPI_OEM_ID = "HPQOEM"
    }
    "lenovo" {
        $BIOS_VENDOR = "LENOVO"
        $BIOS_VERSION = "M1AKT59A"
        $BIOS_RELEASE_DATE = "11/03/2022"
        $SYSTEM_VENDOR = "LENOVO"
        $SYSTEM_PRODUCT = "ThinkCentre M720q"
        $BOARD_PRODUCT = "3106SDK0J40705"
        $DISK_MODEL = "Samsung SSD 860 EVO 500GB"
        $ACPI_OEM_ID = "LENOVO"
    }
    "asus" {
        $BIOS_VENDOR = "American Megatrends Inc."
        $BIOS_VERSION = "1401"
        $BIOS_RELEASE_DATE = "09/20/2022"
        $SYSTEM_VENDOR = "ASUSTeK COMPUTER INC."
        $SYSTEM_PRODUCT = "PRIME B560M-A"
        $BOARD_PRODUCT = "PRIME B560M-A"
        $DISK_MODEL = "Samsung SSD 980 PRO 500GB"
        $ACPI_OEM_ID = "ALASKA"
    }
}

# DMI/SMBIOS BIOS Information
Write-Section "DMI/SMBIOS BIOS Information"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor" "$BIOS_VENDOR"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion" "$BIOS_VERSION"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate" "$BIOS_RELEASE_DATE"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMajor" 5
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMinor" 12
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMajor" 5
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMinor" 12
Write-Success "BIOS information configured (Date: $BIOS_RELEASE_DATE)"
Write-Host ""

# DMI/SMBIOS System Information
Write-Section "DMI/SMBIOS System Information"
$SystemUUID = [guid]::NewGuid().ToString()
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor" "$SYSTEM_VENDOR"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct" "$SYSTEM_PRODUCT"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion" "1.0"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial" "$SYSTEM_SERIAL"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU" "0A12"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily" "Desktop"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemUuid" "$SystemUUID"
Write-Success "System information configured"
Write-Host ""

# DMI/SMBIOS Board Information
Write-Section "DMI/SMBIOS Board Information"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor" "$SYSTEM_VENDOR"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct" "$BOARD_PRODUCT"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVersion" "A00"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardSerial" "$BOARD_SERIAL"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardAssetTag" "Default"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardLocInChass" "Default"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardBoardType" 10
Write-Success "Board information configured"
Write-Host ""

# DMI/SMBIOS Chassis Information
Write-Section "DMI/SMBIOS Chassis Information"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor" "$SYSTEM_VENDOR"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVersion" "1.0"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisSerial" "$CHASSIS_SERIAL"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisAssetTag" "Default"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisType" 3
Write-Success "Chassis information configured"
Write-Host ""

# ACPI Configuration
Write-Section "ACPI Configuration"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/acpi/0/Config/AcpiOemId" "$ACPI_OEM_ID"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/acpi/0/Config/AcpiCreatorId" "INTL"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/acpi/0/Config/AcpiCreatorRev" "0x20210331"
Write-Success "ACPI tables configured"
Write-Host "⚠️  Note: ACPI VBOX__ entries require guest-side registry cleanup" -ForegroundColor Yellow
Write-Host ""

# Disk Configuration
Write-Section "Disk Configuration (AHCI/IDE/NVMe)"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/ahci/0/Config/Port0/ModelNumber" "$DISK_MODEL"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/ahci/0/Config/Port0/SerialNumber" "$DISK_SERIAL"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/ahci/0/Config/Port0/FirmwareRevision" "SVT02B6Q"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/piix3ide/0/Config/PrimaryMaster/ModelNumber" "$DISK_MODEL"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/piix3ide/0/Config/PrimaryMaster/SerialNumber" "$DISK_SERIAL"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/piix3ide/0/Config/PrimaryMaster/FirmwareRevision" "01.01A01"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/nvme/0/Config/ModelNumber" "$DISK_MODEL"
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/nvme/0/Config/SerialNumber" "$DISK_SERIAL"
Write-Success "Disk information configured"
Write-Host ""

# CPU Configuration
Write-Section "CPU Configuration"
& $VBoxManage modifyvm "$VMName" --paravirtprovider none
& $VBoxManage modifyvm "$VMName" --cpuid-set 0x00000001 0x000306a9 0x00020800 0x7fbae3ff 0xbfebfbff

# Remove hypervisor CPUID leaves
for ($i = 0; $i -le 6; $i++) {
    & $VBoxManage modifyvm "$VMName" --cpuid-remove (0x40000000 + $i)
}

# Remove extended CPUID leaves
& $VBoxManage modifyvm "$VMName" --cpuid-remove 0x80000001

Write-Success "CPUID leaves masked"
Write-Host ""

# Timing and Performance
Write-Section "Timing and Performance"
& $VBoxManage setextradata "$VMName" "VBoxInternal/TM/TSCTiedToExecution" 1
& $VBoxManage modifyvm "$VMName" --largepages on
& $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
Write-Success "Timing optimizations applied"
Write-Host ""

# Network Configuration
Write-Section "Network Configuration"
# Generate a realistic Intel MAC address (00:1A:2B:xx:xx:xx)
$MacAddressParts = @("00", "1A", "2B", [string]::Format("{0:X2}", (Get-Random -Minimum 0 -Maximum 256)), [string]::Format("{0:X2}", (Get-Random -Minimum 0 -Maximum 256)), [string]::Format("{0:X2}", (Get-Random -Minimum 0 -Maximum 256)))
$RANDOM_MAC = $MacAddressParts -join ":"
$RANDOM_MAC_HEX = ($MacAddressParts -join "").ToLower()

& $VBoxManage modifyvm "$VMName" --macaddress1 $RANDOM_MAC_HEX
Write-Success "MAC address changed to: $RANDOM_MAC"
Write-Host ""

# Additional Stealth Settings
Write-Section "Additional Stealth Settings"
& $VBoxManage modifyvm "$VMName" --nested-hw-virt off

# Get current firmware
$vminfo = & $VBoxManage showvminfo "$VMName" --machinereadable
$currentFirmware = ($vminfo | Select-String "^firmware=").ToString().Split('"')[1]
Write-Host "Current firmware: $currentFirmware" -ForegroundColor White
Write-Host "⚠️  Consider using --firmware efi for more realistic modern hardware emulation" -ForegroundColor Yellow
Write-Host "   (requires OS reinstall if switching from BIOS)" -ForegroundColor Yellow
Write-Host ""

# Configuration Summary
Write-Section "Configuration Summary"
Write-Host "System Vendor:     $SYSTEM_VENDOR" -ForegroundColor White
Write-Host "System Product:    $SYSTEM_PRODUCT" -ForegroundColor White
Write-Host "BIOS Vendor:       $BIOS_VENDOR" -ForegroundColor White
Write-Host "BIOS Version:      $BIOS_VERSION" -ForegroundColor White
Write-Host "BIOS Date:         $BIOS_RELEASE_DATE" -ForegroundColor White
Write-Host "System Serial:     $SYSTEM_SERIAL" -ForegroundColor White
Write-Host "Disk Model:        $DISK_MODEL" -ForegroundColor White
Write-Host "MAC Address:       $RANDOM_MAC" -ForegroundColor White
Write-Host "Paravirt Provider: none" -ForegroundColor White
Write-Host "TSC Mode:          Tied to execution" -ForegroundColor White
Write-Host ""

# Next Steps
Write-Section "IMPORTANT: Next Steps"
Write-Host ""
Write-Host "1. START THE VM" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. RUN VBoxCloak.ps1 inside Windows:" -ForegroundColor Yellow
Write-Host "   PowerShell -ExecutionPolicy Bypass -File VBoxCloak.ps1 -all" -ForegroundColor White
Write-Host ""
Write-Host "3. DISABLE/REMOVE these features in Windows:" -ForegroundColor Yellow
Write-Host "   • VirtualBox Guest Additions (uninstall completely)" -ForegroundColor White
Write-Host "   • Shared folders" -ForegroundColor White
Write-Host "   • Bidirectional clipboard" -ForegroundColor White
Write-Host "   • Drag and drop" -ForegroundColor White
Write-Host ""
Write-Host "4. VERIFY in Device Manager:" -ForegroundColor Yellow
Write-Host "   • No VirtualBox devices should be visible" -ForegroundColor White
Write-Host "   • Remove any 'Unknown devices' related to VBox" -ForegroundColor White
Write-Host ""
Write-Host "5. TEST with detection tools:" -ForegroundColor Yellow
Write-Host "   • al-khaser" -ForegroundColor White
Write-Host "   • pafish" -ForegroundColor White
Write-Host "   • Ensure Guest Additions are fully removed first" -ForegroundColor White
Write-Host ""

# Known Limitations
Write-Section "Known Limitations (Cannot be Fixed)"
Write-Host ""
Write-Host "The following detections will likely remain:" -ForegroundColor White
Write-Host "• WMI class instance checks (Win32_PhysicalMemory, etc.)" -ForegroundColor White
Write-Host "• Thermal zone information (MSAcpi_ThermalZoneTemperature)" -ForegroundColor White
Write-Host "• Some CIM sensor classes" -ForegroundColor White
Write-Host "• Power management capability differences" -ForegroundColor White
Write-Host "• Hardware timing variations" -ForegroundColor White
Write-Host ""
Write-Host "These are inherent to VirtualBox's architecture and would" -ForegroundColor White
Write-Host "require kernel-mode drivers or source code modifications." -ForegroundColor White
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
